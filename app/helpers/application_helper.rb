module ApplicationHelper
  def color_with_alpha(color, alpha)
    return nil unless color.present?

    # Convert hex to RGB and add alpha
    hex = color.delete('#')
    r, g, b = hex.scan(/../).map(&:hex)
    "rgba(#{r}, #{g}, #{b}, #{alpha})"
  end
end
