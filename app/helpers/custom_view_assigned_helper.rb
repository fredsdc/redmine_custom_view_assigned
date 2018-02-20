module CustomViewAssignedHelper
  def assignable_users(issue)
    current_project = Project.find(issue.project_id)

    target_roles = WorkflowRule.where('old_status_id = ? AND tracker_id = ? AND type = ? AND workspace_id = ?',
                     issue.status_id, issue.tracker_id, WorkflowTransition, current_project.workspace_id).pluck(:role_id).uniq

    [ current_project.users_by_role.collect{|k, r| target_roles.include?(k.id) ? r : []},
      target_roles.include?(3) ? User.active.visible.not_member_of(current_project) : [] ].flatten.uniq.sort_by{|u| u.name.downcase}
  end

  def reassign(issues)
    users = nil
    issues.uniq{|a| [a.status_id, a.project_id, a.tracker_id]}.each do |issue|
      users = users.nil? ? assignable_users(issue) : users & assignable_users(issue)
    end
    users
  end
end
