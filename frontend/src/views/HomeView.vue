<template>
  <div class="home-page">
    <!-- 头部 -->
    <header class="header">
      <div class="header-content">
        <div class="logo">
          <h1>案件思维导图系统</h1>
          <p>数据统计总览</p>
        </div>
        <div class="auth-section">
          <button v-if="!isAuthenticated" @click="goToLogin" class="login-btn">
            登录
          </button>
          <div v-else class="user-menu">
            <span class="welcome">欢迎，{{ user?.real_name || user?.username }}</span>
            <button @click="goToDashboard" class="dashboard-btn">个人仪表板</button>
            <button @click="logout" class="logout-btn">退出</button>
          </div>
        </div>
      </div>
    </header>

    <!-- 主要内容 -->
    <main class="main-content">
      <!-- 统计概览 -->
      <section class="stats-overview">
        <div class="stats-grid">
          <div class="stat-card main-card">
            <div class="stat-content">
              <h3>{{ statistics.total_cases }} 起</h3>
              <p>案件总数</p>
              <div class="amount-breakdown">
                <div class="amount-item amount-low">
                  <span class="amount-label">10万-50万</span>
                  <span class="amount-value">{{ statistics.amount_10_50 }}</span>
                </div>
                <div class="amount-item amount-medium">
                  <span class="amount-label">50万-100万</span>
                  <span class="amount-value">{{ statistics.amount_50_100 }}</span>
                </div>
                <div class="amount-item amount-high">
                  <span class="amount-label">100万以上</span>
                  <span class="amount-value">{{ statistics.amount_100_plus }}</span>
                </div>
              </div>
            </div>
          </div>

          <div class="stat-card main-card">
            <div class="stat-content">
              <h3>{{ statistics.total_users }} 人</h3>
              <p>注册用户</p>
            </div>
          </div>
        </div>
      </section>

      <!-- 单位列表 -->
      <section class="departments-section">
        <h2>单位详情</h2>
        <div class="departments-grid">
          <div v-for="department in departments" :key="department.name" class="department-card"
            :class="{ expanded: expandedDepartments.has(department.name) }" @click="toggleDepartment(department.name)">
            <div class="department-header">
              <div class="department-info">
                <div class="department-icon">🏢</div>
                <div>
                  <h3>{{ department.display_name }}</h3>
                  <p class="department-stats">
                    {{ department.case_count }} 个案件 • {{ department.node_count }} 个节点 • {{ department.attachment_count
                    }} 个附件
                  </p>
                  <div class="amount-breakdown">
                    <span class="amount-item dept-amount-low">10-50万: {{ department.amount_10_50 }}</span>
                    <span class="amount-item dept-amount-medium">50-100万: {{ department.amount_50_100 }}</span>
                    <span class="amount-item dept-amount-high">100万+: {{ department.amount_100_plus }}</span>
                  </div>
                </div>
              </div>
              <div class="expand-icon" :class="{ rotated: expandedDepartments.has(department.name) }">
                ▼
              </div>
            </div>

            <!-- 展开的案件列表 -->
            <div v-if="expandedDepartments.has(department.name)" class="cases-list">
              <div v-if="department.cases.length === 0" class="no-cases">
                暂无案件
              </div>
              <div v-else v-for="case_item in department.cases" :key="case_item.id" class="case-item">
                <div class="case-icon">📋</div>
                <div class="case-info">
                  <h4>{{ case_item.name }}</h4>
                  <p class="case-description">{{ case_item.description || '暂无描述' }}</p>
                  <div v-if="case_item.case_amount" class="case-amount">
                    <span class="amount-label">涉案金额:</span>
                    <span class="amount-value">{{ formatAmount(case_item.case_amount) }}</span>
                  </div>
                  <div class="case-stats">
                    <span class="stat">
                      <span class="stat-icon">🔗</span>
                      {{ case_item.node_count }} 个节点
                    </span>
                    <span class="stat">
                      <span class="stat-icon">📎</span>
                      {{ case_item.attachment_count }} 个附件
                    </span>
                    <span class="stat">
                      <span class="stat-icon">📅</span>
                      {{ formatDate(case_item.created_at) }}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>
    </main>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading-overlay">
      <div class="loading-spinner"></div>
      <p>加载数据中...</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { statisticsAPI } from '@/api'

const router = useRouter()
const authStore = useAuthStore()

// 定义类型
interface DepartmentStats {
  name: string
  display_name: string
  case_count: number
  node_count: number
  attachment_count: number
  amount_10_50: number
  amount_50_100: number
  amount_100_plus: number
  cases: CaseStats[]
}

interface CaseStats {
  id: number
  name: string
  description: string
  node_count: number
  attachment_count: number
  case_amount: number | null
  created_at: string
}

interface Statistics {
  total_cases: number
  total_users: number
  amount_10_50: number
  amount_50_100: number
  amount_100_plus: number
}

// 响应式数据
const loading = ref(true)
const expandedDepartments = ref(new Set<string>())
const statistics = ref<Statistics>({
  total_cases: 0,
  total_users: 0,
  amount_10_50: 0,
  amount_50_100: 0,
  amount_100_plus: 0
})
const departments = ref<DepartmentStats[]>([])

// 计算属性
const isAuthenticated = computed(() => authStore.isAuthenticated)
const user = computed(() => authStore.user)

// 方法
const loadData = async () => {
  try {
    loading.value = true
    const [statsResponse, departmentsResponse] = await Promise.all([
      statisticsAPI.getPublicStatistics(),
      statisticsAPI.getDepartmentStatistics()
    ])

    statistics.value = statsResponse.data
    departments.value = departmentsResponse.data
  } catch (error) {
    console.error('加载数据失败:', error)
  } finally {
    loading.value = false
  }
}

const toggleDepartment = (departmentName: string) => {
  if (expandedDepartments.value.has(departmentName)) {
    expandedDepartments.value.delete(departmentName)
  } else {
    expandedDepartments.value.add(departmentName)
  }
}

const goToLogin = () => {
  router.push('/login')
}

const goToDashboard = () => {
  router.push('/dashboard')
}

const logout = async () => {
  try {
    await authStore.logout()
    router.push('/')
  } catch (error) {
    console.error('退出登录失败:', error)
  }
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('zh-CN')
}

const formatAmount = (amount: number | null | undefined) => {
  if (!amount || amount === 0) return '0 元'
  if (isNaN(amount)) return '未知金额'
  return new Intl.NumberFormat('zh-CN', {
    style: 'currency',
    currency: 'CNY'
  }).format(amount)
}

// 生命周期
onMounted(() => {
  loadData()
})
</script>

<style scoped>
.home-page {
  min-height: 100vh;
  background: #f8f9fa;
}

.header {
  background: white;
  border-bottom: 1px solid #e5e5e5;
  padding: 1rem 0;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo h1 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.8rem;
  font-weight: 700;
}

.logo p {
  margin: 0.25rem 0 0 0;
  color: #666;
  font-size: 0.9rem;
}

.auth-section {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.login-btn,
.dashboard-btn,
.logout-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.login-btn {
  background: #667eea;
  color: white;
}

.login-btn:hover {
  background: #5a6fd8;
}

.dashboard-btn {
  background: #48bb78;
  color: white;
}

.dashboard-btn:hover {
  background: #38a169;
}

.logout-btn {
  background: #e53e3e;
  color: white;
}

.logout-btn:hover {
  background: #c53030;
}

.user-menu {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.welcome {
  color: #2c3e50;
  font-weight: 600;
}

.main-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.stats-overview {
  margin-bottom: 3rem;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
}

.stat-card.main-card {
  background: white;
  border-radius: 8px;
  padding: 2rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 1px solid #e5e5e5;
  border-left: 4px solid #409eff;
  transition: box-shadow 0.3s ease;
}

.stat-card.main-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.stat-content {
  width: 100%;
}

.stat-content h3 {
  margin: 0 0 0.5rem 0;
  font-size: 2rem;
  font-weight: 700;
  color: #2c3e50;
}

.stat-content p {
  margin: 0 0 1rem 0;
  color: #666;
  font-size: 1rem;
  font-weight: 500;
}

.amount-breakdown {
  display: flex;
  flex-direction: row;
  gap: 0.75rem;
  margin-top: 1rem;
  flex-wrap: wrap;
}

.amount-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.4rem 0.6rem;
  border-radius: 4px;
  font-size: 0.85rem;
  white-space: nowrap;
  border-left: 3px solid;
}

.amount-item.amount-low {
  background: #e8f5e8;
  color: #2d5016;
  border-left-color: #4caf50;
}

.amount-item.amount-medium {
  background: #fff3cd;
  color: #856404;
  border-left-color: #ffc107;
}

.amount-item.amount-high {
  background: #f8d7da;
  color: #721c24;
  border-left-color: #dc3545;
}

.amount-label {
  font-size: 0.85rem;
  font-weight: 500;
}

.amount-value {
  font-size: 0.85rem;
  font-weight: 600;
}

.amount-item.amount-low .amount-label,
.amount-item.amount-low .amount-value {
  color: #2d5016;
}

.amount-item.amount-medium .amount-label,
.amount-item.amount-medium .amount-value {
  color: #856404;
}

.amount-item.amount-high .amount-label,
.amount-item.amount-high .amount-value {
  color: #721c24;
}

.departments-section h2 {
  color: #2c3e50;
  font-size: 1.8rem;
  margin-bottom: 2rem;
  text-align: center;
  font-weight: 600;
}

.departments-grid {
  display: grid;
  gap: 1.5rem;
}

.department-card {
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border: 1px solid #e5e5e5;
  transition: all 0.3s ease;
  cursor: pointer;
}

.department-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.department-header {
  padding: 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.department-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex: 1;
}

.department-icon {
  font-size: 2rem;
  width: 50px;
  height: 50px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #409eff;
  color: white;
  border-radius: 8px;
  flex-shrink: 0;
}

.department-info h3 {
  margin: 0;
  color: #2c3e50;
  font-size: 1.4rem;
  font-weight: 700;
}

.department-stats {
  margin: 0.5rem 0 0 0;
  color: #666;
  font-size: 0.9rem;
}

.amount-breakdown {
  display: flex;
  gap: 0.75rem;
  margin-top: 0.5rem;
  flex-wrap: wrap;
}

/* 单位详情部分的金额区间样式 */
.dept-amount-low {
  background: #e8f5e8 !important;
  color: #2d5016 !important;
  border-left: 3px solid #4caf50 !important;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 500;
}

.dept-amount-medium {
  background: #fff3cd !important;
  color: #856404 !important;
  border-left: 3px solid #ffc107 !important;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 500;
}

.dept-amount-high {
  background: #f8d7da !important;
  color: #721c24 !important;
  border-left: 3px solid #dc3545 !important;
  padding: 0.25rem 0.5rem;
  border-radius: 4px;
  font-size: 0.75rem;
  font-weight: 500;
}

.expand-icon {
  color: #666;
  font-size: 1.2rem;
  transition: transform 0.3s ease;
}

.expand-icon.rotated {
  transform: rotate(180deg);
}

.cases-list {
  border-top: 1px solid #e2e8f0;
  padding: 0;
}

.no-cases {
  padding: 2rem;
  text-align: center;
  color: #666;
  font-style: italic;
}

.case-item {
  padding: 1.5rem;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  align-items: flex-start;
  gap: 1rem;
  transition: background-color 0.2s ease;
}

.case-item:hover {
  background-color: #f8fafc;
}

.case-item:last-child {
  border-bottom: none;
}

.case-icon {
  font-size: 1.5rem;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #e2e8f0;
  border-radius: 8px;
  flex-shrink: 0;
}

.case-info {
  flex: 1;
}

.case-info h4 {
  margin: 0 0 0.5rem 0;
  color: #2c3e50;
  font-size: 1.1rem;
  font-weight: 600;
}

.case-description {
  margin: 0 0 1rem 0;
  color: #666;
  font-size: 0.9rem;
  line-height: 1.4;
}

.case-amount {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
  padding: 0.5rem 0.75rem;
  background: #f0f9ff;
  color: #1e40af;
  border-radius: 4px;
  border-left: 3px solid #409eff;
  font-size: 0.9rem;
  font-weight: 600;
}

.amount-label {
  font-weight: 500;
}

.amount-value {
  font-weight: 700;
  font-size: 1rem;
}

.case-stats {
  display: flex;
  gap: 1.5rem;
  flex-wrap: wrap;
}

.stat {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: #666;
  font-size: 0.85rem;
}

.stat-icon {
  font-size: 0.8rem;
}

.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(5px);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.loading-spinner {
  width: 60px;
  height: 60px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-top: 4px solid white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

.loading-overlay p {
  color: white;
  font-size: 1.1rem;
  font-weight: 500;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }

  100% {
    transform: rotate(360deg);
  }
}

@media (max-width: 768px) {
  .header-content {
    padding: 0 1rem;
    flex-direction: column;
    gap: 1rem;
  }

  .main-content {
    padding: 1rem;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .stat-card {
    padding: 1.5rem;
  }

  .stat-icon {
    font-size: 2.5rem;
    width: 60px;
    height: 60px;
  }

  .stat-content h3 {
    font-size: 2rem;
  }

  .department-header {
    padding: 1rem;
  }

  .case-item {
    padding: 1rem;
  }

  .case-stats {
    flex-direction: column;
    gap: 0.5rem;
  }
}
</style>
