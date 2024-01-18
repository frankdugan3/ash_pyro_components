import 'phoenix_html'
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import topbar from '../vendor/topbar'
import { hooks, getTimezone, sendTimezoneToServer } from 'pyro_components'

sendTimezoneToServer()

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content')
let liveSocket = new LiveSocket('/live', Socket, {
  params: { _csrf_token: csrfToken, timezone: getTimezone() },
  hooks: { ...hooks },
  metadata: {
    click: (e, el) => {
      return {
        shiftKey: e.shiftKey,
        ctrlKey: e.ctrlKey,
        // detail: e.detail || 1,
      }
    },
    // keydown: (e, el) => {
    //   return {
    //     altKey: e.altKey,
    //     code: e.code,
    //     ctrlKey: e.ctrlKey,
    //     key: e.key,
    //     shiftKey: e.shiftKey,
    //   }
    // },
    // keyup: (e, el) => {
    //   return {
    //     altKey: e.altKey,
    //     code: e.code,
    //     ctrlKey: e.ctrlKey,
    //     key: e.key,
    //     shiftKey: e.shiftKey,
    //   }
    // },
  },
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: '#29d' }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', (_info) => topbar.show(300))
window.addEventListener('phx:page-loading-stop', (_info) => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

if (process.env.NODE_ENV !== 'production') {
  liveSocket.enableDebug()
  window.liveSocket = liveSocket
}

console.log(`What, you think you're some kind of developer? Get out of my space!!

(╯°□°）╯︵ ┻━┻`)
