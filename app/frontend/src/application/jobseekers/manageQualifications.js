export const ADD_SUBJECT_ID = 'add_subject';
export const CONTAINER_ELEMENT_CLASSNAME = '.add-subject';
export const DELETE_BUTTON_CLASSNAME = 'delete-button';
export const GOVUK_ERROR_MESSAGE_CLASSNAME = '.govuk-error-message';
export const GOVUK_INPUT_CLASSNAME = '.govuk-input';

export const rows = () => document.getElementsByClassName('subject-row');

export const removeErrors = (column) => {
  column.className = column.className.replace(/\bgovuk-form-group--error\b/g, '');
  column.innerHTML = column.innerHTML.replace(/field-error\b/g, 'field');
  column.innerHTML = column.innerHTML.replace(/govuk-input--error\b/g, '');
  column.querySelector(GOVUK_ERROR_MESSAGE_CLASSNAME).remove();
  column.querySelector(GOVUK_INPUT_CLASSNAME).removeAttribute('aria-describedby');
};

export const renumberColumn = (column, newNumber, keepValues, keepErrors) => {
  let input = column.querySelector(GOVUK_INPUT_CLASSNAME);
  let inputValue;
  if (input && keepValues) {
    inputValue = input.value;
  }
  column.id = column.id.replace(/\d+/g, `${newNumber}`);
  column.innerHTML = column.innerHTML.replace(/\d+/g, `${newNumber}`);
  if (!keepErrors && column.querySelector(GOVUK_ERROR_MESSAGE_CLASSNAME)) {
    manageQualifications.removeErrors(column);
  }
  input = column.querySelector(GOVUK_INPUT_CLASSNAME);
  if (input) {
    if (inputValue && keepValues) {
      input.value = inputValue;
    } else {
      input.removeAttribute('value');
      input.removeAttribute('aria-required');
    }
  }
};

export const renumberRow = (row, newNumber, keepValues, keepErrors) => {
  row.id = `subject_row_${newNumber}`;
  const columns = row.children;
  let i;
  for (i = 0; i < columns.length; i++) {
    manageQualifications.renumberColumn(columns[i], newNumber, keepValues, keepErrors);
  }
};

export const renumberRemainingRows = (deletedIndex) => {
  const subjectRows = manageQualifications.rows();
  let i;
  for (i = 0; i < subjectRows.length; i++) {
    if (i >= deletedIndex - 1) {
      manageQualifications.renumberRow(subjectRows[i], i + 1, true, true);
    }
  }
};

export const addDeletionEventListener = (newNumber) => {
  document.getElementById(`delete_${newNumber}`).addEventListener('click', (event) => {
    event.preventDefault();
    const indexToDelete = event.target.id.replace(/\D/g, '');
    document.getElementById(`subject_row_${indexToDelete}`).remove();
    manageQualifications.renumberRemainingRows(indexToDelete);
  });
};

export const insertAddSubjectLink = () => {
  if (document.querySelector(CONTAINER_ELEMENT_CLASSNAME)) {
    document.querySelector(CONTAINER_ELEMENT_CLASSNAME).innerHTML = `
      <div class="govuk-!-margin-bottom-6">
        <a id="${ADD_SUBJECT_ID}"
           class="govuk-link govuk-!-font-size-19"
           href="#"
           rel="nofollow">+ Add another subject</a>
      </div>`;
    const addSubjectLink = document.getElementById(ADD_SUBJECT_ID);
    const fieldset = document.getElementById('subjects-and-grades');

    if (addSubjectLink && fieldset) {
      addSubjectLink.addEventListener('click', (e) => {
        e.preventDefault();

        const originalRows = manageQualifications.rows();
        const newNumber = originalRows.length + 1;

        if (originalRows && newNumber) {
          const newRow = originalRows[originalRows.length - 1].cloneNode(true);
          if (!newRow.lastElementChild.className.includes(DELETE_BUTTON_CLASSNAME)) {
            manageQualifications.insertDeleteButton(newRow, newNumber);
          }
          fieldset.appendChild(newRow);
          manageQualifications.renumberRow(newRow, originalRows.length, false, false);
          manageQualifications.addDeletionEventListener(newNumber);
          newRow.querySelector(GOVUK_INPUT_CLASSNAME).focus();
        }
      });
    }
  }
};

export const insertDeleteButton = (row, newNumber) => {
  row.insertAdjacentHTML('beforeend', `<a id="delete_${newNumber}"
    class="govuk-link ${DELETE_BUTTON_CLASSNAME} govuk-!-margin-bottom-6 govuk-!-padding-bottom-2"
    rel="nofollow"
    href="#">delete subject</a>`);
};

window.addEventListener('DOMContentLoaded', () => {
  manageQualifications.insertAddSubjectLink();

  let i;
  for (i = 1; i < manageQualifications.rows().length; i++) {
    manageQualifications.addDeletionEventListener(i + 1);
  }
});

const manageQualifications = {
  addDeletionEventListener,
  insertAddSubjectLink,
  insertDeleteButton,
  removeErrors,
  renumberColumn,
  renumberRemainingRows,
  renumberRow,
  rows,
};

export default manageQualifications;
