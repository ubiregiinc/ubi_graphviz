require './spec/spec_helper'

conn = { adapter: "sqlite3", database: ":memory:" }
ActiveRecord::Base.establish_connection(conn)

class Account < ActiveRecord::Base
  connection.create_table :accounts, force: true do |t|
    t.string :login
    t.timestamps
  end
  has_many :child_links, dependent: :destroy, class_name: "ParentChildLink", foreign_key: :parent_id
  has_many :children, through: :child_links
  has_many :parent_links, dependent: :destroy, class_name: "ParentChildLink", foreign_key: :child_id
  has_many :parents, through: :parent_links
end

class ParentChildLink < ActiveRecord::Base
  attr_writer :accepted
  connection.create_table :parent_child_links, force: true do |t|
    t.string :child_id, :parent_id, :child_name, null: false
    t.timestamps
  end
  belongs_to :parent, class_name: "Account"
  belongs_to :child, class_name: "Account"
end

# 本体のrailsアプリでそのまま動くようにラップする
class FactoryBot
  def self.create(_name=nil, login: )
    Account.create!(login: login)
  end
end

RSpec.describe UbiGraphviz::AccountModel do
  let(:filename) { 'ubi_graphviz_for_test' }
  after(:each) do
    FileUtils.rm_rf("#{filename}.dot")
  end

  describe 'シンプルな3層' do
    #    parent
    #    ↑    ↑
    # child1  child2
    #         ↑
    #         child1_child1
    it 'generate success' do
      @parent = FactoryBot.create(:blank_account, login: :parent)
      @child1 = FactoryBot.create(:blank_account, login: :child1)
      @child2 = FactoryBot.create(:blank_account, login: :child2)
      @child1_child1 = FactoryBot.create(:blank_account, login: :child1_child1)
      ParentChildLink.create!(parent: @parent, child: @child1,child_name: 'parent_child1', accepted: true)
      ParentChildLink.create!(parent: @parent, child: @child2,child_name: 'parent_child2', accepted: true)
      ParentChildLink.create!(parent: @child1, child: @child1_child1, child_name: 'child1_child1', accepted: true)
      ubi_graphviz = UbiGraphviz::AccountModel.new(@child2, method_name: :login, filename: filename)
      expect(ubi_graphviz.parent_child_links.size).to eq(3)
      ubi_graphviz.write
      expect(ubi_graphviz.code).to eq(
        <<~EOF
        digraph g{
          child2[
            style = "filled";
          ]
          graph[
            layout = dot;
          ]
        "child1" -> "parent";
        "child2" -> "parent";
        "child1_child1" -> "child1";

          { rank = min; parent;parent; }
          { rank = max; child2;child1_child1; }
        }
        EOF
      )
    end
  end
end
