# frozen_string_literal: true

module ReadableVacancyHelper
  # simplecov:disable
  def vacancy_contract_type_with_duration(model)
    return nil if model.contract_type.blank?

    return I18n.t("publishers.vacancies.build.contract_type.#{model.contract_type}") if model.fixed_term_contract_duration.blank?

    if model.is_parental_leave_cover
      [I18n.t("publishers.vacancies.build.contract_type.#{model.contract_type}"),  model.fixed_term_contract_duration, I18n.t("publishers.vacancies.build.contract_type.parental_leave")].compact.join(" - ")
    else
      [I18n.t("publishers.vacancies.build.contract_type.#{model.contract_type}"),  model.fixed_term_contract_duration].compact.join(" - ")
    end
  end
  # simplecov:enable

  def vacancy_readable_subjects(model)
    model.subjects.join(", ")
  end

  def vacancy_readable_visa_sponsorship_availability(model)
    ["visa sponsorship"] if model.visa_sponsorship_available
  end

  def school_group_names
    organisations.map { |organisation|
      if organisation.is_a?(SchoolGroup)
        organisation.name
      else
        organisation.school_groups.map(&:name).compact_blank
      end
    }.flatten.uniq
  end

  def school_group_types
    organisations.map { |organisation|
      if organisation.is_a?(SchoolGroup)
        organisation.group_type
      else
        organisation.school_groups.map(&:group_type).compact_blank
      end
    }.flatten.uniq
  end

  def religious_character
    organisations.filter_map { |organisation| organisation.religious_character if organisation.is_a?(School) }
  end
end
