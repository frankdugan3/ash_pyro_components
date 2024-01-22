// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const path = require('path')

module.exports = {
  darkMode: 'class',
  content: [
    './js/**/*.js',
    '../lib/ash_pyro_components_example_web.ex',
    '../lib/ash_pyro_components_example/**/*.*ex',
    '../lib/ash_pyro_components_example_web/**/*.*ex',
    // '../../deps/pyro_components/lib/pyro_components/overrides/bem.ex',
    '../../../pyro_components/lib/pyro_components/overrides/bem.ex',
    '../../lib/ash_pyro_components/overrides/bem.ex',
  ],
  plugins: [
    require('@tailwindcss/forms'),
    require(path.join(
      __dirname,
      // '../../deps/pyro_components/assets/js/tailwind-plugin.js',
      '../../../pyro_components/assets/js/tailwind-plugin.js',
    ))({
      heroIconsPath: path.join(__dirname, '../deps/heroicons/optimized'),
      addBase: true,
    }),
  ],
}
