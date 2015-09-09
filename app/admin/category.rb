ActiveAdmin.register Category do
  permit_params :name

  controller do
    skip_before_action :verify_authenticity_token, only: [:destroy, :create]
    layout 'custom_layout'

    def index
      @category = Category.new
      authorize! :index, @category
      @headers = ['Id', I18n.t('name'), I18n.t('created_at')]
      @scoped_collection = Category.all.order(sort_column + ' ' + sort_direction)
      render 'custom_index'
    end

    def create
      @category = Category.new(permitted_params[:category])
      if @category.save
        redirect_to categories_path, flash: { success: "Category created" } 
      else
        redirect_to categories_path, flash: { error: "#{@category.errors.full_messages.first}" }
      end
    end

    def show
      @category = Category.find_by(id: params[:id])
      authorize! :show, @category
      render 'custom_show'
    end

    def edit
      @category = Category.find_by(id: params[:id])
      authorize! :edit, @category
      render 'custom_edit'
    end

    def update
      @category = Category.find_by(id: params[:id])
      if @category.update(permitted_params[:category])
        redirect_to category_path(@category), flash: { success: "Successfully updated!" }
      else
        redirect_to edit_category_path(@category), object: @category, flash: { error: "#{ @category.errors.full_messages.first }" }
      end
    end

    private

    def sort_column
      Category.column_names.include?(params[:sort]) ? params[:sort] : 'categories.name'
    end

    def sort_direction
      %w(asc desc).include?(params[:direction]) ? params[:direction] : 'asc'
    end
  end
end
