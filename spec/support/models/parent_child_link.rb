class ParentChildLink < ActiveRecord::Base
  attr_writer :accepted
  connection.create_table :parent_child_links, force: true do |t|
    t.string :child_id, :parent_id, :child_name, null: false
    t.timestamps
  end
  belongs_to :parent, class_name: "Account"
  belongs_to :child, class_name: "Account"
end
