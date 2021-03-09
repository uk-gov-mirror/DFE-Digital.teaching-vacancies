## Rails view components
JS and SCSS files are optional
```
/app
  /components
    /my_widget_component
      my_widget_component.js
      my_widget_component.test.js
      my_widget_component.scss
      my_widget_component.html.slim
    my_widget_component.rb
```

The `_component` postfix is integral to how view components work and is essential.

### Slim usage
`= render(MyWidgetComponent.new()`

### SCSS usage
all component JS and SASS is added to the webpack pipeline using the script `frontend/src/components.js`

For the SASS to take advantage of GovUK frontend, you should import the relvant part of the GovUK fronend library. Settings/Tools/Helpers/Base all out no CSS so they should be explicitly imported to the component SASS as thety do not out CSS themselves and hence will not bloat the CSS bundle. Also components should use the GovUK mixins not variables. e.g `govuk-colour("mid-grey")` NOT `$govuk-border-colour`

Components should have outermost CSS class namespaced to `my-widget-component` and then all internal styles for the component contained within the SCSS block for the namespace, i.e

```scss
.my-widget-component {
  .my-widget-component__header {
    // header styles
  }
}
```
