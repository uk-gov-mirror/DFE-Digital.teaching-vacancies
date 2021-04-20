class Jobseekers::JobApplications::QualificationsController < Jobseekers::BaseController
  include QualificationFormConcerns

  helper_method :back_path, :category, :form, :job_application, :qualifications, :submit_text

  def submit_category
    if form.valid?
      redirect_to new_jobseekers_job_application_qualification_path(qualification_params)
    else
      render :select_category
    end
  end

  def create
    if form.valid?
      subject_and_grade_param_keys.each_slice(2) do |subject_and_grade_keys|
        job_application.qualifications.create(qualification_params.permit(unique_param_keys.concat(subject_and_grade_keys))
                                                                  .transform_keys { |key| key.split(/_\d+/).first })
      end
      update_in_progress_steps!(:qualifications)
      redirect_to back_path
    else
      render :new
    end
  end

  def update
    if form.valid?
      qualification.update(qualification_params)
      redirect_to back_path
    else
      render :edit
    end
  end

  def destroy
    count = qualifications.count
    qualifications.each(&:destroy)
    redirect_to back_path, success: t(".success", count: count)
  end

  private

  def form
    @form ||= form_class(category).new(form_attributes)
  end

  def form_attributes
    case action_name
    when "new"
      { category: category, count: 1 }
    when "select_category"
      {}
    when "edit"
      attributes = qualifications.first.slice(:category, :finished_studying, :finished_studying_details, :institution, :name, :year)
      qualifications.each_with_index do |qualification, index|
        attributes.merge!(qualification.slice(:subject, :grade).transform_keys { |key| "#{key}_#{index + 1}" })
      end
      attributes.merge(count: qualifications.count)
    when "create", "update", "submit_category"
      qualification_params
    end
  end

  def qualification_params
    case action_name
    when "new", "select_category", "submit_category"
      (params[form_param_key(category)] || params).permit(:category)
    when "create", "edit", "update"
      params.require(form_param_key(category)).permit(unique_param_keys.concat(subject_and_grade_param_keys))
            .merge(count: subject_and_grade_param_keys.count / 2)
    end
  end

  def unique_param_keys
    %i[category finished_studying finished_studying_details institution name year]
  end

  def subject_and_grade_param_keys
    params.require(form_param_key(category)).keys.select { |key| /\Asubject_\d+\z/.match?(key) }
  end

  def category
    @category ||= if action_name.in?(%w[edit update])
                    qualifications.first.category
                  else
                    params.permit(:category)[:category]
                  end
  end

  def back_path
    @back_path ||= jobseekers_job_application_build_path(job_application, :qualifications)
  end

  def job_application
    @job_application ||= current_jobseeker.job_applications.draft.find(params[:job_application_id])
  end

  def qualifications
    @qualifications ||= [job_application.qualifications.find(params[:ids])].flatten
  end

  def submit_text
    category.in?(%w[undergraduate postgraduate other]) ? t("buttons.save_qualification.one") : t("buttons.save_qualification.other")
  end
end
