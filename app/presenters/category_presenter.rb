class CategoryPresenter
  def initialize(category, template)
    @category = category
    @template = template
  end

  def h
    @template
  end

  def sortable(column, direction)
    column = column.parameterize.underscore
    h.link_to h.params.merge(sort: column, direction: direction) do
      h.render partial: direction == 'asc' ? '/goals/arrow_top' : '/goals/arrow_down'  
    end
  end

  def name_as_link(category)
    h.link_to category.name, h.category_path(category), class:'link_goal_name'
  end

  def view(category)
    h.link_to I18n.t('view'), h.category_path(category)
  end

  def delete(category)
    h.link_to I18n.t('delete'), h.category_path(category), method: :delete
  end

  def edit(category)
    h.link_to I18n.t('edit'), h.edit_category_path(category)
  end

end