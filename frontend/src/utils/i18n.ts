// 简单的国际化配置
const messages = {
  zh: {
    toolbar: {
      more: '更多',
      displayOutline: '显示大纲',
      baseStyle: '基础样式',
      theme: '主题',
      strusture: '结构',
      newFile: '新建',
      openFile: '打开',
      saveAs: '另存为',
      import: '导入',
      export: '导出',
      shortcutKey: '快捷键',
      tip: '提示',
      editingLocalFileTipFront: '正在编辑本地文件：',
      editingLocalFileTipEnd: '',
      fileContentError: '文件内容错误',
      fileOpenFailed: '文件打开失败',
      selectFileTip: '请选择文件',
      notSupportTip: '浏览器不支持',
      defaultFileName: '思维导图',
      creatingTip: '创建中...',
      saving: '保存中...',
      saved: '保存成功'
    }
  },
  en: {
    toolbar: {
      more: 'More',
      displayOutline: 'Outline',
      baseStyle: 'Style',
      theme: 'Theme',
      strusture: 'Structure',
      newFile: 'New',
      openFile: 'Open',
      saveAs: 'Save As',
      import: 'Import',
      export: 'Export',
      shortcutKey: 'Shortcuts',
      tip: 'Tip',
      editingLocalFileTipFront: 'Editing local file: ',
      editingLocalFileTipEnd: '',
      fileContentError: 'File content error',
      fileOpenFailed: 'Failed to open file',
      selectFileTip: 'Please select a file',
      notSupportTip: 'Browser not supported',
      defaultFileName: 'Mind Map',
      creatingTip: 'Creating...',
      saving: 'Saving...',
      saved: 'Saved'
    }
  }
}

let currentLang = 'zh'

export const $t = (key: string) => {
  const keys = key.split('.')
  let value: any = messages[currentLang as keyof typeof messages]
  
  for (const k of keys) {
    value = value?.[k]
  }
  
  return value || key
}

export const setLanguage = (lang: string) => {
  currentLang = lang
}

export { messages }
