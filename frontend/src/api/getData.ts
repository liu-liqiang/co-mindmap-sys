// 获取思维导图数据的函数
import { useMindMapStore } from '@/stores/mindmap'

export const getData = () => {
  const mindmapStore = useMindMapStore()
  // 这里应该返回当前思维导图的数据
  // 需要根据实际的数据结构来实现
  return {
    root: {
      data: {
        text: '中心主题'
      },
      children: []
    }
  }
}

export default getData
