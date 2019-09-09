module Ubiquity::WorkShowActionsHelper

  def delete_pop_up_message(presenter, request_path)

    if (request_path == "/dashboard/my/works") && (work_status_code(presenter.solr_document.id) == 200)
      link_to " Delete Work", [main_app, presenter], class:'glyphicon glyphicon-trash', data: { confirm: "Warning: This #{presenter.human_readable_type} has a live DOI. Deleting the work will cause the DOI to lead to a non-existent page." }, method: :delete
    elsif (request_path == "/dashboard/my/works")
      link_to " Delete Work", [main_app, presenter], class:'glyphicon glyphicon-trash', data: { confirm: "Deleting a work is permanent. Click OK to delete this work, or Cancel to cancel this operation" }, method: :delete
    elsif work_status_code(presenter.solr_document.id) == 200
      link_to "Delete", [main_app, presenter], class: 'btn btn-danger', data: { confirm: "Warning: This #{presenter.human_readable_type} has a live DOI. Deleting the work will cause the DOI to lead to a non-existent page." }, method: :delete
    else
      link_to "Delete", [main_app, presenter], class: 'btn btn-danger', data: { confirm: "Delete this #{presenter.human_readable_type}?" }, method: :delete
    end


  end

  private

  def work_status_code(work_id)
    work = ExternalService.where(work_id: work_id).first
    work['data']['status_code'] if work
  end

end
