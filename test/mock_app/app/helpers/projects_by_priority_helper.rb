module ProjectsByPriorityHelper
  def project_active_scaffold_tab_options(column, record)
    if column.tabbed_by == :priority
      Task::PRIORITIES.map { |label, value| [label, value] }
    else
      active_scaffold_tab_options(column, record)
    end
  end
end