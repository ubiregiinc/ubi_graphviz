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

# 本体のrailsアプリでそのまま動くようにラップする
class FactoryBot
  def self.create(_name=nil, login: )
    Account.create!(login: login)
  end
end
