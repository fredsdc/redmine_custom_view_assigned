module CustomViewAssignedHelper
  def assignable_users(issue)
    current_project = Project.find(issue.project_id)

    workflow_rules = WorkflowRule.where('old_status_id = ? AND tracker_id = ? AND type = ?', issue.status_id, issue.tracker_id, WorkflowTransition).group(:role_id).pluck(:role_id)
    target_roles = MemberRole.select { |role| workflow_rules.include?(role.role_id) }.map(&:member_id).sort
    target_members = Member.select { |member| target_roles.include?(member.id) &&
        member.project_id == current_project.id }.map(&:user_id).sort

    types = ['User']
    types << 'Group' if Setting.issue_group_assignment?

    users = current_project.member_principals.select { |m| types.include?(m.principal.type) &&
        m.roles.detect(&:assignable) && target_members.include?(m.principal.id) }.map(&:principal).sort
    users.uniq.sort
  end
end
