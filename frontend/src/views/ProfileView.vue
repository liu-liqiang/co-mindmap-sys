<template>
    <AppLayout>
        <template #header>
            <div class="profile-header">
                <h1>个人资料</h1>
                <p>管理您的个人信息和账户设置</p>
            </div>
        </template>

        <div class="profile-container">
            <div class="profile-content">
                <el-row :gutter="24">
                    <!-- 左侧个人信息卡片 -->
                    <el-col :span="8">
                        <el-card class="profile-card">
                            <div class="avatar-section">
                                <el-avatar :size="80" class="profile-avatar">
                                    {{ user?.real_name?.charAt(user?.real_name?.length - 1).toUpperCase() }}
                                </el-avatar>
                                <h3>{{ user?.real_name || user?.username }}</h3>
                                <p class="user-role">{{ user?.department_display || '未设置部门' }}</p>
                            </div>
                            <el-divider />
                            <div class="stats-section">
                                <div class="stat-item">
                                    <span class="stat-label">注册时间</span>
                                    <span class="stat-value">{{ formatDate(user?.date_joined) }}</span>
                                </div>
                                <div class="stat-item">
                                    <span class="stat-label">最后登录</span>
                                    <span class="stat-value">{{ formatDate(user?.last_login) }}</span>
                                </div>
                            </div>
                        </el-card>
                    </el-col>

                    <!-- 右侧个人信息展示和密码修改 -->
                    <el-col :span="16">
                        <!-- 个人信息展示卡片 -->
                        <el-card class="form-card">
                            <template #header>
                                <div class="card-header">
                                    <span>个人信息</span>
                                </div>
                            </template>

                            <div class="info-display">
                                <div class="info-item">
                                    <span class="info-label">真实姓名:</span>
                                    <span class="info-value">{{ user?.real_name || '未设置' }}</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">用户名:</span>
                                    <span class="info-value">{{ user?.username || '未设置' }}</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">警号:</span>
                                    <span class="info-value">{{ user?.police_number || '未设置' }}</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">手机号码:</span>
                                    <span class="info-value">{{ user?.phone_number || '未设置' }}</span>
                                </div>
                                <div class="info-item">
                                    <span class="info-label">所属部门:</span>
                                    <span class="info-value">{{ user?.department_display || user?.department || '未设置'
                                    }}</span>
                                </div>
                                <div class="info-note">
                                    <el-icon>
                                        <InfoFilled />
                                    </el-icon>
                                    个人信息由管理员统一管理，如需修改请联系管理员
                                </div>
                            </div>
                        </el-card>

                        <!-- 修改密码卡片 -->
                        <el-card class="form-card password-card">
                            <template #header>
                                <div class="card-header">
                                    <span>修改密码</span>
                                </div>
                            </template>

                            <el-form ref="passwordFormRef" :model="passwordForm" :rules="passwordRules"
                                label-width="100px" class="password-form">
                                <el-form-item label="当前密码" prop="current_password">
                                    <el-input v-model="passwordForm.current_password" type="password"
                                        placeholder="请输入当前密码" :disabled="passwordLoading" show-password />
                                </el-form-item>

                                <el-form-item label="新密码" prop="new_password">
                                    <el-input v-model="passwordForm.new_password" type="password" placeholder="请输入新密码"
                                        :disabled="passwordLoading" show-password />
                                </el-form-item>

                                <el-form-item label="确认密码" prop="confirm_password">
                                    <el-input v-model="passwordForm.confirm_password" type="password"
                                        placeholder="请再次输入新密码" :disabled="passwordLoading" show-password />
                                </el-form-item>

                                <el-form-item>
                                    <el-button type="primary" @click="handlePasswordChange" :loading="passwordLoading">
                                        修改密码
                                    </el-button>
                                    <el-button @click="handlePasswordReset" :disabled="passwordLoading">
                                        重置
                                    </el-button>
                                </el-form-item>
                            </el-form>
                        </el-card>
                    </el-col>
                </el-row>
            </div>
        </div>
    </AppLayout>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { InfoFilled } from '@element-plus/icons-vue'
import type { FormInstance, FormRules } from 'element-plus'
import { useAuthStore } from '@/stores/auth'
import { userAPI } from '@/api'
import AppLayout from '@/components/AppLayout.vue'

const authStore = useAuthStore()
const passwordFormRef = ref<FormInstance>()
const passwordLoading = ref(false)

// 获取当前用户信息
const user = computed(() => authStore.user)

// 密码修改表单
const passwordForm = reactive({
    current_password: '',
    new_password: '',
    confirm_password: ''
})

// 密码修改表单验证规则
const passwordRules: FormRules = {
    current_password: [
        { required: true, message: '请输入当前密码', trigger: 'blur' }
    ],
    new_password: [
        { required: true, message: '请输入新密码', trigger: 'blur' },
        { min: 6, message: '密码长度不能少于6位', trigger: 'blur' }
    ],
    confirm_password: [
        { required: true, message: '请确认新密码', trigger: 'blur' },
        {
            validator: (rule, value, callback) => {
                if (value !== passwordForm.new_password) {
                    callback(new Error('两次输入的密码不一致'))
                } else {
                    callback()
                }
            },
            trigger: 'blur'
        }
    ]
}

// 格式化日期
const formatDate = (dateString: string | undefined) => {
    if (!dateString) return '未知'
    const date = new Date(dateString)
    return date.toLocaleDateString('zh-CN')
}

// 修改密码
const handlePasswordChange = async () => {
    if (!passwordFormRef.value) return

    try {
        await passwordFormRef.value.validate()
        passwordLoading.value = true

        // 调用API修改密码
        await userAPI.changePassword({
            current_password: passwordForm.current_password,
            new_password: passwordForm.new_password
        })

        ElMessage.success('密码修改成功')
        handlePasswordReset()
    } catch (error: any) {
        console.error('修改密码失败:', error)

        // 处理具体的错误信息
        if (error.response?.data?.message) {
            ElMessage.error(error.response.data.message)
        } else if (error.response?.data?.current_password) {
            ElMessage.error('当前密码错误')
        } else if (error.response?.data?.new_password) {
            ElMessage.error('新密码格式不正确')
        } else {
            ElMessage.error('修改密码失败，请重试')
        }
    } finally {
        passwordLoading.value = false
    }
}

// 重置密码表单
const handlePasswordReset = () => {
    Object.assign(passwordForm, {
        current_password: '',
        new_password: '',
        confirm_password: ''
    })
    passwordFormRef.value?.clearValidate()
}
</script>

<style scoped>
.profile-header {
    margin-bottom: 20px;
}

.profile-header h1 {
    margin: 0 0 8px 0;
    color: #2c3e50;
    font-size: 24px;
    font-weight: 600;
}

.profile-header p {
    margin: 0;
    color: #666;
    font-size: 14px;
}

.profile-container {
    width: 100%;
    height: 100%;
    overflow: hidden;
}

.profile-content {
    height: 100%;
    overflow-y: auto;
    padding-right: 8px;
}

/* 滚动条样式 */
.profile-content::-webkit-scrollbar {
    width: 6px;
}

.profile-content::-webkit-scrollbar-track {
    background: #f1f1f1;
    border-radius: 3px;
}

.profile-content::-webkit-scrollbar-thumb {
    background: #c1c1c1;
    border-radius: 3px;
}

.profile-content::-webkit-scrollbar-thumb:hover {
    background: #a1a1a1;
}

.profile-card {
    margin-bottom: 20px;
}

.avatar-section {
    text-align: center;
    padding: 20px 0;
}

.profile-avatar {
    margin-bottom: 16px;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    font-size: 32px;
    font-weight: 600;
}

.avatar-section h3 {
    margin: 0 0 8px 0;
    color: #2c3e50;
    font-size: 18px;
    font-weight: 600;
}

.user-role {
    margin: 4px 0;
    color: #409EFF;
    font-size: 14px;
    font-weight: 500;
}

.user-email {
    margin: 4px 0;
    color: #666;
    font-size: 14px;
}

.stats-section {
    padding-top: 16px;
}

.stat-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 8px 0;
    border-bottom: 1px solid #f0f0f0;
}

.stat-item:last-child {
    border-bottom: none;
}

.stat-label {
    color: #666;
    font-size: 14px;
}

.stat-value {
    color: #2c3e50;
    font-size: 14px;
    font-weight: 500;
}

.form-card {
    margin-bottom: 20px;
}

.card-header {
    font-weight: 600;
    color: #2c3e50;
}

.info-display {
    padding: 20px 0;
}

.info-item {
    display: flex;
    align-items: center;
    padding: 12px 0;
    border-bottom: 1px solid #f0f0f0;
}

.info-item:last-child {
    border-bottom: none;
    margin-bottom: 16px;
}

.info-label {
    color: #666;
    font-size: 14px;
    font-weight: 500;
    width: 100px;
    flex-shrink: 0;
}

.info-value {
    color: #2c3e50;
    font-size: 14px;
    font-weight: 500;
    flex: 1;
}

.info-note {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px 16px;
    background: #f0f9ff;
    border: 1px solid #bfdbfe;
    border-radius: 6px;
    color: #1e40af;
    font-size: 13px;
    margin-top: 16px;
}

.password-form {
    padding: 20px 0;
}

.password-card {
    margin-top: 20px;
}

:deep(.el-form-item__label) {
    font-weight: 500;
    color: #606266;
}

:deep(.el-input.is-disabled .el-input__inner) {
    background-color: #f5f7fa;
    color: #999;
}

/* 响应式设计 */
@media (max-width: 768px) {
    .profile-container :deep(.el-col) {
        width: 100% !important;
        margin-bottom: 20px;
    }

    .profile-content {
        padding-right: 0;
    }

    .avatar-section {
        padding: 16px 0;
    }

    .profile-avatar {
        margin-bottom: 12px;
    }
}
</style>
