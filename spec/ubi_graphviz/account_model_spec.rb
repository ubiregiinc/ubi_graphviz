require './spec/spec_helper'

RSpec.describe UbiGraphviz::AccountModel do
  describe 'シンプルな3層' do
    #    parent
    #    ↑    ↑
    # child1  child2
    #          ↑
    #         child1_child1
    it 'be success' do
      parent = FactoryBot.create(:blank_account, login: :parent)
      child1 = FactoryBot.create(:blank_account, login: :child1)
      child2 = FactoryBot.create(:blank_account, login: :child2)
      child1_child1 = FactoryBot.create(:blank_account, login: :child1_child1)
      ParentChildLink.create!(parent: parent, child: child1,child_name: 'parent_child1', accepted: true)
      ParentChildLink.create!(parent: parent, child: child2,child_name: 'parent_child2', accepted: true)
      ParentChildLink.create!(parent: child1, child: child1_child1, child_name: 'child1_child1', accepted: true)
      [parent, child1, child2, child1_child1].each do |account|
        ubi_graphviz = UbiGraphviz::AccountModel.new(account, method_name: :login)
        expect(ubi_graphviz.parent_child_links.size).to eq(3)
      end
      ubi_graphviz = UbiGraphviz::AccountModel.new(child2, method_name: :login)
      expect(ubi_graphviz.parent_child_links.size).to eq(3)
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

  describe '2層親子で相互' do
    #    account1
    #      ↑ ↓
    #    account2
    it 'be success' do
      account1 = FactoryBot.create(:blank_account, login: :account1)
      account2 = FactoryBot.create(:blank_account, login: :account2)
      ParentChildLink.create!(parent: account1, child: account2, child_name: 'child1_1', accepted: true)
      ParentChildLink.create!(parent: account2, child: account1, child_name: 'child2_parent1', accepted: true)
      [account1, account2].each do |account|
        ubi_graphviz = UbiGraphviz::AccountModel.new(account, method_name: :login)
        expect(ubi_graphviz.parent_child_links.size).to eq(2)
      end
    end
  end

  describe '3層共通の親が1つ' do
    #      parent2         parent1
    #      ↑    ↑          ↑  ↑
    #      |   child2_parent12   |
    #      |         ↑          |
    #      |     child4_child2   |
    # child3_parent2      child1_parent1
    it 'be success' do
      parent1 = FactoryBot.create(:blank_account, login: :parent1)
      parent2 = FactoryBot.create(:blank_account, login: :parent2)
      child1_parent1 = FactoryBot.create(:blank_account, login: :child1_parent1)
      child2_parent12 = FactoryBot.create(:blank_account, login: :child2_parent12)
      child3_parent2 = FactoryBot.create(:blank_account, login: :child3_parent2)
      child4_child2 = FactoryBot.create(:blank_account, login: :child4_child2)
      ParentChildLink.create!(parent: parent1, child: child1_parent1, child_name: 'child1_1', accepted: true)
      ParentChildLink.create!(parent: parent1, child: child2_parent12, child_name: 'child2_parent1', accepted: true)
      ParentChildLink.create!(parent: parent2, child: child2_parent12, child_name: 'child2_parent2', accepted: true)
      ParentChildLink.create!(parent: parent2, child: child3_parent2, child_name: 'child3_parent2', accepted: true)
      ParentChildLink.create!(parent: child2_parent12, child: child4_child2, child_name: 'child4_child2', accepted: true)
      [parent1, parent2, child1_parent1, child2_parent12, child3_parent2, child4_child2].each do |account|
        ubi_graphviz = UbiGraphviz::AccountModel.new(account, method_name: :login)
        expect(ubi_graphviz.parent_child_links.size).to eq(5)
      end
    end
  end

  describe '3層共通の親が1つ(一部相互リンク)' do
    #      parent2         parent1
    #      ↑    ↑          ↑  ↑
    #      |   child2_parent12   |
    #      |        ↑ ↓        |
    #      |     child4_child2   |
    # child3_parent2      child1_parent1
    it 'be success' do
      parent1 = FactoryBot.create(:blank_account, login: :parent1)
      parent2 = FactoryBot.create(:blank_account, login: :parent2)
      child1_parent1 = FactoryBot.create(:blank_account, login: :child1_parent1)
      child2_parent12 = FactoryBot.create(:blank_account, login: :child2_parent12)
      child3_parent2 = FactoryBot.create(:blank_account, login: :child3_parent2)
      child4_child2 = FactoryBot.create(:blank_account, login: :child4_child2)
      ParentChildLink.create!(parent: parent1, child: child1_parent1, child_name: 'child1_1', accepted: true)
      ParentChildLink.create!(parent: parent1, child: child2_parent12, child_name: 'child2_parent1', accepted: true)
      ParentChildLink.create!(parent: parent2, child: child2_parent12, child_name: 'child2_parent2', accepted: true)
      ParentChildLink.create!(parent: parent2, child: child3_parent2, child_name: 'child3_parent2', accepted: true)
      ParentChildLink.create!(parent: child2_parent12, child: child4_child2, child_name: 'child4_child2', accepted: true)
      ParentChildLink.create!(parent: child4_child2, child: child2_parent12, child_name: 'child4_child2', accepted: true)
      [parent1, parent2, child1_parent1, child2_parent12, child3_parent2, child4_child2].each do |account|
        ubi_graphviz = UbiGraphviz::AccountModel.new(account, method_name: :login)
        ubi_graphviz.write
        expect(ubi_graphviz.parent_child_links.size).to eq(6)
      end
    end
  end

  describe '3層共通の親が1つ(全部相互リンク)' do
    #       parent2         parent1
    #      ↑|   ↑↓      ↓↑ | ↑
    #      | | child2_parent12  | |
    #      | |        ↑ ↓     | |
    #      | ↓   child4_child2 ↓|
    # child3_parent2      child1_parent1
    it 'be success' do
      parent1 = FactoryBot.create(:blank_account, login: :parent1)
      parent2 = FactoryBot.create(:blank_account, login: :parent2)
      child1_parent1 = FactoryBot.create(:blank_account, login: :child1_parent1)
      child2_parent12 = FactoryBot.create(:blank_account, login: :child2_parent12)
      child3_parent2 = FactoryBot.create(:blank_account, login: :child3_parent2)
      child4_child2 = FactoryBot.create(:blank_account, login: :child4_child2)
      ParentChildLink.create!(parent: parent1, child: child1_parent1, child_name: 'child1_1', accepted: true)
      ParentChildLink.create!(parent: child1_parent1, child: parent1, child_name: 'child1_1', accepted: true)
      ParentChildLink.create!(parent: parent1, child: child2_parent12, child_name: 'child2_parent1', accepted: true)
      ParentChildLink.create!(parent: child2_parent12, child: parent1, child_name: 'child2_parent1', accepted: true)
      ParentChildLink.create!(parent: parent2, child: child2_parent12, child_name: 'child2_parent2', accepted: true)
      ParentChildLink.create!(parent: parent2, child: child3_parent2, child_name: 'child3_parent2', accepted: true)
      ParentChildLink.create!(parent: child3_parent2, child: parent2, child_name: 'child3_parent2', accepted: true)
      ParentChildLink.create!(parent: child2_parent12, child: parent2, child_name: 'child3_parent2', accepted: true)
      ParentChildLink.create!(parent: child2_parent12, child: child4_child2, child_name: 'child4_child2', accepted: true)
      ParentChildLink.create!(parent: child4_child2, child: child2_parent12, child_name: 'child4_child2', accepted: true)
      [parent1, parent2, child1_parent1, child2_parent12, child3_parent2, child4_child2].each do |account|
        ubi_graphviz = UbiGraphviz::AccountModel.new(account, method_name: :login)
        ubi_graphviz.write
        expect(ubi_graphviz.parent_child_links.size).to eq(10)
      end
    end
  end

  describe '2層横が多い' do
    it 'be success' do
      accounts = [
        parent1 = FactoryBot.create(:blank_account, login: :parent1),
        parent2 = FactoryBot.create(:blank_account, login: :parent2),
        parent3 = FactoryBot.create(:blank_account, login: :parent3),
        parent4 = FactoryBot.create(:blank_account, login: :parent4),
        parent5 = FactoryBot.create(:blank_account, login: :parent5),
        child1  = FactoryBot.create(:blank_account, login: :child1),
        child2  = FactoryBot.create(:blank_account, login: :child2),
        child3  = FactoryBot.create(:blank_account, login: :child3),
        child4  = FactoryBot.create(:blank_account, login: :child4),
        child5  = FactoryBot.create(:blank_account, login: :child5),
      ]
      ParentChildLink.create!(parent: parent1, child: child1,child_name: 'parent1_child1', accepted: true)
      ParentChildLink.create!(parent: parent1, child: child2,child_name: 'parent1_child2', accepted: true)
      ParentChildLink.create!(parent: parent2, child: child2,child_name: 'parent2_child2', accepted: true)
      ParentChildLink.create!(parent: parent2, child: child3,child_name: 'parent2_child3', accepted: true)
      ParentChildLink.create!(parent: parent3, child: child3,child_name: 'parent3_child3', accepted: true)
      ParentChildLink.create!(parent: parent3, child: child4,child_name: 'parent3_child4', accepted: true)
      ParentChildLink.create!(parent: parent4, child: child4,child_name: 'parent4_child4', accepted: true)
      ParentChildLink.create!(parent: parent4, child: child5,child_name: 'parent4_child5', accepted: true)
      ParentChildLink.create!(parent: parent5, child: child5,child_name: 'parent5_child5', accepted: true)
      accounts.each do |account|
        ubi_graphviz = UbiGraphviz::AccountModel.new(account, method_name: :login)
        expect(ubi_graphviz.parent_child_links.size).to eq(9)
      end
    end
  end

  describe '親子なし' do
    it 'be success' do
      account = FactoryBot.create(:blank_account, login: :parent)
      ubi_graphviz = UbiGraphviz::AccountModel.new(account, method_name: :login)
      expect(ubi_graphviz.parent_child_links.size).to eq(0)
    end
  end
end
