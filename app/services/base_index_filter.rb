class BaseIndexFilter
  attr_reader :params, :search_field, :sort_field, :sort_order
  attr_accessor :records

  def initialize(records:, params:, search_field: :name, sort_field: :name, sort_order: :asc)
    @records = records
    @params = params
    @search_field = search_field
    @sort_field = sort_field
    @sort_order = sort_order
  end

  def call
    filter_search
    order_and_page
    records
  end

  private

  def filter_search
    return unless params[:filter_search].present?

    self.records = records.where(search_query)
  end

  def order_and_page
    self.records = records.order(sort_field => sort_order).page(params[:page]).per(10)
  end

  def search_query
    params[:filter_search].split(" ").map do |search_term|
      "#{search_field} ILIKE '%#{search_term}%'"
    end.join(" AND ")
  end
end
