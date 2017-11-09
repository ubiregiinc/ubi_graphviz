module UbiGraphviz
  class AccountModel
    attr_reader :account, :code, :filename, :method_name

    # account: 探索を開始するAcocuntインスタンス
    # filename: ファイルに保存する時にこの名前で保存する
    # method_name: このメソッドの出力が画像にした時の1要素に表示するラベルの名前になる
    # max_level: 探索しに幅. 兄弟が多い場合は大きくしないと開始するアカウントによっては拾い漏らしが起きる
    def initialize(account, filename: nil, method_name: nil, max_level: 5)
      @account = account
      @filename = filename || 'account_links'
      @method_name = method_name || :to_s
      @max_level = max_level
      build_dot_code
    end

    def write
      path = [filename, '.dot'].join
      File.write(path, @code)
      self
    end

    def run_dot_command
      system("dot ./#{filename}.dot -Tpng -o ./#{filename}.png")
    end

    def parent_child_links
      @parent_child_links ||= collect_link(get_leafs_links(account))
    end

    private

    def build_dot_code
      if parent_child_links.size.zero?
        @code = build_for_none_links
        return
      end
      edges = parent_child_links.map { |link| build_edge(link) }
      @code = <<~EOH
        digraph g{
          #{account.public_send(method_name)}[
            style = "filled";
          ]
          graph[
            layout = dot;
          ]
        #{edges.join}
        #{rank}
        }
      EOH
    end

    def rank
      min_rank_names = parent_child_links.map(&:parent).find_all { |x| x.parents.empty? }.map(&:"#{method_name}")
      max_rank_names = parent_child_links.map(&:child).find_all { |x| x.children.empty? }.map(&:"#{method_name}")
      if min_rank_names.present? && max_rank_names.present?
        <<~EOH
          { rank = min; #{min_rank_names.join(';')}; }
          { rank = max; #{max_rank_names.join(';')}; }
        EOH
      end
    end

    def build_for_none_links
      <<~EOH
        digraph g{
          #{account.public_send(method_name)}[
            style = "filled";
          ]
        }
      EOH
    end

    def build_edge(parent_child_link)
      child_name = parent_child_link.child.public_send(method_name)
      parent_name = parent_child_link.parent.public_send(method_name)
      <<~EOH
        "#{child_name}" -> "#{parent_name}";
      EOH
    end

    def get_leafs_links(account)
      if account.parents.empty? && account.children.empty?
        return []
      end
      list = 
        case 
        when account.parents.empty? && account.children.exists? # 一番親の時
          list = [OpenStruct.new(parent_id: account.id)]
          down_search(list)
        when account.parents.exists? && account.children.empty? # leafの時
          list = [OpenStruct.new(child_id: account.id)]
          up_search(list)
        else # 中間
          list = [OpenStruct.new(child_id: account.id)]
          up_search(list)
        end
      @max_level.times do
        list = up_search(down_search(list))
      end
      down_search(list)
    end

    def up_search(leaf)
      local_roots = []
      found_links = []
      may_roots = leaf.map { |p| OpenStruct.new(parent_id: p.child_id) }
      loop do
        may_roots = ParentChildLink.where(child_id: may_roots.map(&:parent_id))
        # reject は 相互リンクだと無限ループになるのでそれを回避する
        break if may_roots.reject{ |x|found_links.include?(x) }.empty?
        may_roots.each do |root_link|
          found_links << root_link
          if root_link.parent.parent_links.reject{ |x|found_links.include?(x) }.empty?
            local_roots << root_link
          end
        end
      end
      local_roots
    end

    def down_search(roots)
      local_leaf = []
      found_links = []
      may_leaf = roots.map { |p| OpenStruct.new(child_id: p.parent_id) }
      loop do
        may_leaf = ParentChildLink.where(parent_id: may_leaf.map(&:child_id))
        break if may_leaf.reject{ |x|found_links.include?(x) }.empty?
        may_leaf.each do |leaf_link|
          found_links << leaf_link
          if leaf_link.child.child_links.reject{ |x|found_links.include?(x) }.empty?
            local_leaf << leaf_link
          end
        end
      end
      local_leaf
    end

    def collect_link(leaf_links)
      parent_links = []
      may_parent_links = leaf_links
      loop do
        may_parent_links = ParentChildLink.where(child_id: may_parent_links.map(&:parent_id))
        break if may_parent_links.reject { |x| parent_links.include?(x) }.empty?
        may_parent_links.each do |parent_link|
          parent_links << parent_link
        end
      end
      parent_links.concat(leaf_links).uniq
    end
  end
end
