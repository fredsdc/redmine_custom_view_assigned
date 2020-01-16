module CustomViewAssignedHelper
  def assignable_users(issue)
    target_roles = WorkflowRule.where('old_status_id = ? AND tracker_id = ? AND type = ? AND workspace_id = ?',
                     issue.status_id, issue.tracker_id, WorkflowTransition, issue.project.workspace_id).pluck(:role_id).uniq
    target_roles |= WorkflowRule.where('new_status_id = ? AND tracker_id = ? AND type = ? AND workspace_id = ?',
                     issue.status_id, issue.tracker_id, WorkflowTransition, issue.project.workspace_id).pluck(:role_id).uniq if issue.closed?

    types = ['User']
    types << 'Group' if Setting.issue_group_assignment?

    principals = Principal.active.joins(:members => :roles).
      where(:type => types, :members => {:project_id => issue.project_id}, :roles => {:id => target_roles, :assignable => true}).to_a

    unless issue.new_record?
      issue_orig=Issue.find(issue.id)
      principals |= [issue_orig.assigned_to] if issue_orig.status_id == issue.status_id unless issue_orig.assigned_to.nil?
    end

    principals.uniq.sort_by{|p| p.name.downcase}
  end

  def reassign(issues)
    users = nil
    issues.uniq{|a| [a.status_id, a.project_id, a.tracker_id]}.each do |issue|
      users = users.nil? ? assignable_users(issue) : users & assignable_users(issue)
    end
    users
  end
end
