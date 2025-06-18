module ApplicationHelper
  def page_range(page, page_count)
    range_start = [1, page - 5].max
    page_count = page_count.clamp(1..)
    range_end = (page + 5).clamp(1, page_count)
    (range_start..range_end).to_a
  end
end
