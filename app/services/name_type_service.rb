class NameTypeService < Hyrax::QaSelectService
  def initialize(_authority_name = nil)
    super("name_type.#{I18n.locale}")
  end
end
