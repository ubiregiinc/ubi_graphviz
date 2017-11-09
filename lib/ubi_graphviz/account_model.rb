module UbiGraphviz
  class AccountModel
    attr_reader :account, :code, :filename, :method_name

    def initialize(account, filename: nil, method_name: nil)
      @account = account
      @filename = filename || 'account_links'
      @method_name = method_name || :to_s
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
        return 
      end
      edges = parent_child_links.map { |link| build_edge(link) }
      min_rank_names = parent_child_links.map(&:parent).find_all { |x| x.parents.empty? }.map(&:"#{method_name}")
      max_rank_names = parent_child_links.map(&:child).find_all { |x| x.children.empty? }.map(&:"#{method_name}")
      @code = <<~EOH
        digraph g{
          #{account.public_send(method_name)}[
            style = "filled";
          ]
          graph[
            layout = dot;
          ]
        #{edges.join}
          { rank = min; #{min_rank_names.join(';')}; }
          { rank = max; #{max_rank_names.join(';')}; }
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
      5.times do
        list = up_search(down_search(list, debug: nil), debug: false)
      end
      down_search(list)
    end

    def up_search(leaf, debug: false)
      local_roots = []
      may_roots = leaf.map { |p| OpenStruct.new(parent_id: p.child_id) }
      binding.pry if debug
      loop do
        # may_roots = may_roots.flat_map { |x| ParentChildLink.where(child_id: x.parent_id) }
        may_roots = ParentChildLink.where(child_id: may_roots.map(&:parent_id))
        break if may_roots.empty?
        may_roots.each do |root_link|
          if root_link.parent.parents.empty?
            local_roots << root_link
          end
        end
      end
      local_roots
    end

    def down_search(roots, debug: false)
      local_leaf = []
      may_leaf = roots.map { |p| OpenStruct.new(child_id: p.parent_id) }
      binding.pry if debug
      loop do
        may_leaf = ParentChildLink.where(parent_id: may_leaf.map(&:child_id))
        break if may_leaf.empty?
        may_leaf.each do |leaf_link|
          local_leaf << leaf_link if leaf_link.child.children.empty?
        end
      end
      local_leaf
    end

    def collect_link(leaf_links)
      parent_links = []
      may_parent_links = leaf_links
      loop do
        may_parent_links = ParentChildLink.where(child_id: may_parent_links.map(&:parent_id))
        break if may_parent_links.empty?
        may_parent_links.each do |parent_link|
          parent_links << parent_link
        end
      end
      parent_links.concat(leaf_links)
    end
  end
end
