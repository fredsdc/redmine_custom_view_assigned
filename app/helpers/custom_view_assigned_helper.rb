module CustomViewAssignedHelper
  def assignable_users(issue)
    target_roles = WorkflowRule.where('old_status_id = ? AND tracker_id = ? AND type = ? AND workspace_id = ?',
                     issue.status_id, issue.tracker_id, WorkflowTransition, issue.project.workspace_id).pluck(:role_id).uniq

    types = ['User']
    types << 'Group' if Setting.issue_group_assignment?

    (Principal.active.joins(:members => :roles).
      where(:type => types, :members => {:project_id => issue.project_id}, :roles => {:id => target_roles, :assignable => true}).to_a |
      (issue.new_record? ? [] : [Issue.find(issue.id).assigned_to])
    ).uniq.sort_by{|p| p.name.downcase}
  end

  def reassign(issues)
    users = nil
    issues.uniq{|a| [a.status_id, a.project_id, a.tracker_id]}.each do |issue|
      users = users.nil? ? assignable_users(issue) : users & assignable_users(issue)
    end
    users
  end
end
