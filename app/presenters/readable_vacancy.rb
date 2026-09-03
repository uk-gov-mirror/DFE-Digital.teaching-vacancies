# frozen_string_literal: true

module ReadableVacancy
  # simplecov:disable
  def readable_job_roles
    model.job_roles.map { |job_role|
      I18n.t("helpers.label.publishers_job_listing_job_role_form.job_role_options.#{job_role}")
    }.join(", ")
  end
  # simplecov:enable

  # simplecov:disable
  def readable_key_stages
    model.key_stages&.map { |key_stage|
      I18n.t("helpers.label.publishers_job_listing_key_stages_form.key_stages_options.#{key_stage}")
    }&.join(", ")
  end
  # simplecov:enable

  def readable_job_title
    job_title
  end
end
