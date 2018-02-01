module CustomViewAssignedHelper
  def assignable_users(issue)
    current_project = Project.find(issue.project_id)

    target_roles = WorkflowRule.where('old_status_id = ? AND tracker_id = ? AND type = ? AND workspace_id = ?',
                     issue.status_id, issue.tracker_id, WorkflowTransition, current_project.workspace_id).pluck(:role_id).uniq
    User.select { |m| (m.roles_for_project(current_project).map(&:id) & target_roles).any? &&
                       ! m.roles_for_project(current_project).detect(&:assignable).nil?}.uniq.sort
  end

  def reassign(issues)
    users = nil
    issues.uniq{|a| [a.status_id, a.project_id, a.tracker_id]}.each do |issue|
      users = users.nil? ? assignable_users(issue) : users & assignable_users(issue)
    end
    users
  end
end
