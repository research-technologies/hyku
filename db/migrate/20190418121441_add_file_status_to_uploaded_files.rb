class AddFileStatusToUploadedFiles < ActiveRecord::Migration[5.1]
  def change
    add_column :uploaded_files, :file_status, :integer, default: 0
  end
end
