<template>
  <div class="toolbarContainer">
    <div class="toolbar">
      <!-- 节点操作 -->
      <div class="toolbarBlock">
        <div class="toolbarBtn" @click="handleNodeAction('back')">
          <span class="icon">↩️</span>
          <span class="text">撤销</span>
        </div>
        <div class="toolbarBtn" @click="handleNodeAction('forward')">
          <span class="icon">↪️</span>
          <span class="text">重做</span>
        </div>
        <div class="toolbarBtn" @click="handleNodeAction('siblingNode')">
          <span class="icon">➕</span>
          <span class="text">同级节点</span>
        </div>
        <div class="toolbarBtn" @click="handleNodeAction('childNode')">
          <span class="icon">📁</span>
          <span class="text">子节点</span>
        </div>
        <div class="toolbarBtn" @click="handleNodeAction('deleteNode')">
          <span class="icon">🗑️</span>
          <span class="text">删除</span>
        </div>
      </div>
      
      <!-- 文件操作 -->
      <div class="toolbarBlock">
        <div class="toolbarBtn" @click="handleFileAction('new')">
          <span class="icon">📄</span>
          <span class="text">新建</span>
        </div>
        <div class="toolbarBtn" @click="handleFileAction('open')">
          <span class="icon">📂</span>
          <span class="text">打开</span>
        </div>
        <div class="toolbarBtn" @click="handleFileAction('save')">
          <span class="icon">💾</span>
          <span class="text">保存</span>
        </div>
        <div class="toolbarBtn" @click="$emit('showImport')">
          <span class="icon">📥</span>
          <span class="text">导入</span>
        </div>
        <div class="toolbarBtn" @click="$emit('showExport')">
          <span class="icon">📤</span>
          <span class="text">导出</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'


// 导出组件
// 目前没有使用到具体的导出逻辑，保留了事件定义和基本结构
// 这里可以根据需要添加具体的导出逻辑
// 如果需要导出为特定格式，可以在这里实现
// 例如：导出为 JSON、XML 等格式，或者直接下载文件等操作
// 目前的示例中没有具体的导出逻辑，仅保留了事件定义和基本结构
export default {
  name: 'Toolbar',
  components: {

  },
  data() {
    return {
      list: [
        'back',
        'forward',
        'painter',
        'siblingNode',
        'childNode',
        'deleteNode',
        'image',
        'icon',
        'link',
        'note',
        'tag',
        'summary',
        'associativeLine',
        'formula'
      ],
    }
  },
  computed: {
    // 根据当前屏幕宽度动态调整按钮列表
  },  
}

</script>

<style scoped>
.toolbarContainer {
  display: flex;
  justify-content: center;
  align-items: center;
}

.toolbar {
  display: flex;
  gap: 15px;
  font-size: 12px;
  color: rgba(26, 26, 26, 0.8);
}

.toolbarBlock {
  display: flex;
  background-color: #fff;
  padding: 8px 15px;
  border-radius: 4px;
  box-shadow: 0 1px 8px 0 rgba(0, 0, 0, 0.06);
  border: 1px solid rgba(0, 0, 0, 0.06);
  gap: 15px;
}

.toolbarBtn {
  display: flex;
  flex-direction: column;
  align-items: center;
  cursor: pointer;
  min-width: 40px;
}

.toolbarBtn:hover .icon {
  background: #f0f0f0;
}

.icon {
  display: flex;
  height: 22px;
  background: #fff;
  border-radius: 3px;
  border: 1px solid #e0e0e0;
  justify-content: center;
  align-items: center;
  padding: 0 4px;
  font-size: 12px;
  min-width: 22px;
}

.text {
  margin-top: 2px;
  font-size: 11px;
  text-align: center;
  line-height: 1.2;
}
</style>
