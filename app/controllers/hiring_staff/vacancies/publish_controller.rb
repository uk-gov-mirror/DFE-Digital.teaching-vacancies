class HiringStaff::Vacancies::PublishController < HiringStaff::Vacancies::ApplicationController
  def create
    vacancy = Vacancy.find(vacancy_id)

    if PublishVacancy.new(vacancy: vacancy).call
      reset_session_vacancy!
      redirect_to school_vacancy_summary_path(school_id: school.id, id: vacancy_id)
    else
      redirect_to review_path(vacancy), notice: I18n.t('errors.vacancies.unable_to_publish')
    end
  end

  private

  def vacancy_id
    params.permit(:vacancy_id)[:vacancy_id]
  end
end
