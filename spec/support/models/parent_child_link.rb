class ParentChildLink < ActiveRecord::Base
  attr_writer :accepted
  connection.create_table :parent_child_links, force: true do |t|
    t.string :child_name, null: false
    t.integer :child_id, :parent_id, null: false
    t.timestamps
  end
  belongs_to :parent, class_name: "Account"
  belongs_to :child, class_name: "Account"
end
