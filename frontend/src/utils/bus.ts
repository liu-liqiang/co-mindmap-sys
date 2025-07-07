// 事件总线 - 使用 mitt 库替代 Vue 2 的事件总线
import mitt from 'mitt'

type Events = {
  setData: any
  write_local_file: any
  lang_change: void
  showOutline: void
  showBaseStyle: void
  showTheme: void
  showStructure: void
  showImport: void
  showExport: void
  showShortcutKey: void
}

const bus = mitt<Events>()

export default bus
