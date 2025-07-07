<template>
    <el-dialog v-model="dialogVisible" title="成员管理" width="800px" @close="handleClose">
        <div class="members-management">
            <!-- 邀请新成员 -->
            <el-card class="invite-card" shadow="never">
                <template #header>
                    <div class="card-header">
                        <span>邀请新成员</span>
                    </div>
                </template>
                <el-form ref="inviteFormRef" :model="inviteForm" :rules="inviteRules" label-width="80px">
                    <el-row :gutter="20">
                        <el-col :span="8">
                            <el-form-item label="单位" prop="department">
                                <el-select v-model="inviteForm.department" placeholder="请选择单位" style="width: 100%"
                                    @change="handleDepartmentChange" clearable>
                                    <el-option label="市局直属部门" value="direct" />
                                    <el-option label="天元分局" value="tianyuan" />
                                    <el-option label="芦淞分局" value="lusong" />
                                    <el-option label="荷塘分局" value="hetang" />
                                    <el-option label="石峰分局" value="shifeng" />
                                    <el-option label="董家塅分局" value="dongjiabai" />
                                    <el-option label="经开区分局" value="kaifaqu" />
                                    <el-option label="渌口分局" value="lukou" />
                                    <el-option label="醴陵市公安局" value="liling" />
                                    <el-option label="攸县公安局" value="youxian" />
                                    <el-option label="茶陵县公安局" value="chaling" />
                                    <el-option label="炎陵县公安局" value="yanling" />
                                </el-select>
                            </el-form-item>
                        </el-col>
                        <el-col :span="10">
                            <el-form-item label="人员" prop="selectedUsers">
                                <el-select v-model="inviteForm.selectedUsers" placeholder="请先选择单位" style="width: 100%"
                                    multiple :disabled="!inviteForm.department" :loading="departmentUsersLoading"
                                    filterable collapse-tags collapse-tags-tooltip>
                                    <el-option v-for="user in departmentUsers" :key="user.id"
                                        :label="`${user.real_name || user.username} (${user.username})`"
                                        :value="user.username" />
                                </el-select>
                            </el-form-item>
                        </el-col>
                        <el-col :span="6">
                            <el-form-item label="权限" prop="permission">
                                <el-select v-model="inviteForm.permission" placeholder="选择权限" style="width: 100%">
                                    <el-option label="只读" value="read" />
                                    <el-option label="编辑" value="edit" />
                                    <el-option label="管理员" value="admin" />
                                </el-select>
                            </el-form-item>
                        </el-col>
                    </el-row>
                    <el-form-item>
                        <el-button type="primary" :loading="inviteLoading" @click="handleBatchInvite">
                            批量邀请
                        </el-button>
                        <el-button @click="resetInviteForm">重置</el-button>
                    </el-form-item>
                </el-form>

                <!-- 直接输入姓名方式 -->
                <el-divider>或者直接输入姓名</el-divider>
                <el-form ref="simpleInviteFormRef" :model="simpleInviteForm" :rules="simpleInviteRules" label-width="80px">
                    <el-row :gutter="20">
                        <el-col :span="8">
                            <el-form-item label="真实姓名" prop="real_name">
                                <el-input 
                                    v-model="simpleInviteForm.real_name" 
                                    placeholder="请输入真实姓名" 
                                    style="width: 100%" 
                                    @change="handleRealNameChange"
                                    clearable
                                />
                            </el-form-item>
                        </el-col>
                        <el-col :span="6">
                            <el-form-item label="单位" prop="department">
                                <el-select 
                                    v-model="simpleInviteForm.department" 
                                    placeholder="请选择单位" 
                                    style="width: 100%"
                                    :disabled="!departmentOptions.length"
                                    @change="handleDepartmentSelectChange"
                                    clearable
                                >
                                    <el-option 
                                        v-for="option in departmentOptions" 
                                        :key="option.value" 
                                        :label="option.label" 
                                        :value="option.value" 
                                    />
                                </el-select>
                            </el-form-item>
                        </el-col>
                        <el-col :span="6">
                            <el-form-item label="警号" prop="police_number">
                                <el-select 
                                    v-model="simpleInviteForm.police_number" 
                                    placeholder="请选择警号" 
                                    style="width: 100%"
                                    :disabled="!policeNumberOptions.length"
                                    @change="handlePoliceNumberChange"
                                    clearable
                                >
                                    <el-option 
                                        v-for="option in policeNumberOptions" 
                                        :key="option.value" 
                                        :label="option.label" 
                                        :value="option.value" 
                                    />
                                </el-select>
                            </el-form-item>
                        </el-col>
                        <el-col :span="4">
                            <el-form-item label="权限" prop="permission">
                                <el-select v-model="simpleInviteForm.permission" placeholder="选择权限" style="width: 100%">
                                    <el-option label="只读" value="read" />
                                    <el-option label="编辑" value="edit" />
                                    <el-option label="管理员" value="admin" />
                                </el-select>
                            </el-form-item>
                        </el-col>
                    </el-row>
                    <el-form-item>
                        <el-button type="success" :loading="simpleInviteLoading" @click="handleSimpleInvite">
                            邀请
                        </el-button>
                        <el-button @click="resetSimpleInviteForm">重置</el-button>
                    </el-form-item>
                </el-form>
            </el-card>

            <!-- 当前成员列表 -->
            <el-card class="members-card" shadow="never">
                <template #header>
                    <div class="card-header">
                        <span>当前成员 ({{ members.length }})</span>
                    </div>
                </template>

                <div v-if="loading" class="loading-container">
                    <el-skeleton :rows="3" animated />
                </div>

                <el-table v-else :data="members" style="width: 100%">
                    <el-table-column label="单位" width="120">
                        <template #default="{ row }">
                            <span class="department-text">{{ getUnitDisplay(row.user.department) }}</span>
                        </template>
                    </el-table-column>

                    <el-table-column label="姓名" min-width="120">
                        <template #default="{ row }">
                            <div class="user-info">
                                <div class="real-name">{{ row.user.real_name || '未设置' }}</div>
                                <div class="username">{{ row.user.username }}</div>
                            </div>
                        </template>
                    </el-table-column>

                    <el-table-column label="权限" width="120">
                        <template #default="{ row }">
                            <el-select v-if="canEditPermission(row)" :model-value="row.permission" size="small"
                                @change="(value: string) => handlePermissionChange(row, value)">
                                <el-option label="只读" value="read" />
                                <el-option label="编辑" value="edit" />
                                <el-option label="管理员" value="admin" />
                            </el-select>
                            <el-tag v-else :type="getPermissionTagType(row.permission)">
                                {{ getPermissionText(row.permission) }}
                            </el-tag>
                        </template>
                    </el-table-column>

                    <el-table-column label="加入时间" width="180">
                        <template #default="{ row }">
                            {{ formatDate(row.joined_at) }}
                        </template>
                    </el-table-column>

                    <el-table-column label="操作" width="100">
                        <template #default="{ row }">
                            <el-button v-if="canRemoveMember(row)" type="danger" size="small" text
                                @click="handleRemoveMember(row)">
                                移除
                            </el-button>
                            <span v-else class="no-action">-</span>
                        </template>
                    </el-table-column>
                </el-table>
            </el-card>
        </div>

        <template #footer>
            <span class="dialog-footer">
                <el-button @click="handleClose">关闭</el-button>
            </span>
        </template>
    </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, watch, computed } from 'vue'
import { useProjectStore, type ProjectMember } from '@/stores/project'
import { useAuthStore } from '@/stores/auth'
import { userAPI } from '@/api'
import { ElMessage, ElMessageBox, type FormInstance, type FormRules } from 'element-plus'

interface User {
    id: number
    username: string
    real_name: string
    department: string
}

interface Props {
    modelValue: boolean
    projectId: number | null
}

interface Emits {
    (e: 'update:modelValue', value: boolean): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const projectStore = useProjectStore()
const authStore = useAuthStore()
const inviteFormRef = ref<FormInstance>()
const simpleInviteFormRef = ref<FormInstance>()
const loading = ref(false)
const inviteLoading = ref(false)
const simpleInviteLoading = ref(false)
const departmentUsersLoading = ref(false)

const dialogVisible = ref(false)
const members = ref<ProjectMember[]>([])
const departmentUsers = ref<User[]>([])

// 新的批量邀请表单
const inviteForm = reactive({
    department: '',
    selectedUsers: [] as string[],
    permission: 'read' as 'read' | 'edit' | 'admin'
})

// 简单邀请表单（改为根据姓名查询）
const simpleInviteForm = reactive({
    real_name: '',
    department: '',
    police_number: '',
    username: '', // 保留用于后端API调用
    permission: 'read' as 'read' | 'edit' | 'admin'
})

const departmentOptions = ref<{ value: string; label: string }[]>([])
const policeNumberOptions = ref<{ value: string; label: string; username: string }[]>([])
const foundUsers = ref<any[]>([])
const searchLoading = ref(false)

const inviteRules: FormRules = {
    selectedUsers: [
        { required: true, message: '请选择人员', trigger: 'change', type: 'array', min: 1 }
    ],
    permission: [
        { required: true, message: '请选择权限', trigger: 'change' }
    ]
}

const simpleInviteRules: FormRules = {
    real_name: [
        { required: true, message: '请输入真实姓名', trigger: 'blur' }
    ],
    department: [
        { required: true, message: '请选择单位', trigger: 'change' }
    ],
    police_number: [
        { required: true, message: '请选择警号', trigger: 'change' }
    ],
    permission: [
        { required: true, message: '请选择权限', trigger: 'change' }
    ]
}

const currentUser = computed(() => authStore.user)

watch(() => props.modelValue, (val) => {
    dialogVisible.value = val
    if (val && props.projectId) {
        fetchMembers()
    }
})

watch(dialogVisible, (val) => {
    emit('update:modelValue', val)
})

const fetchMembers = async () => {
    if (!props.projectId) return

    loading.value = true
    try {
        members.value = await projectStore.fetchProjectMembers(props.projectId)
    } catch (error) {
        ElMessage.error('获取成员列表失败')
    } finally {
        loading.value = false
    }
}

// 获取单位用户列表
const handleDepartmentChange = async (department: string) => {
    if (!department) {
        departmentUsers.value = []
        inviteForm.selectedUsers = []
        return
    }

    departmentUsersLoading.value = true
    try {
        const response = await userAPI.getUsersByDepartment(department)
        departmentUsers.value = response.data
        inviteForm.selectedUsers = []
    } catch (error) {
        ElMessage.error('获取人员列表失败')
        departmentUsers.value = []
    } finally {
        departmentUsersLoading.value = false
    }
}

// 批量邀请成员
const handleBatchInvite = async () => {
    if (!inviteFormRef.value || !props.projectId) return

    try {
        await inviteFormRef.value.validate()
        inviteLoading.value = true

        // 批量邀请所有选中的用户
        const invitePromises = inviteForm.selectedUsers.map(username =>
            projectStore.inviteMember(props.projectId!, {
                username,
                permission: inviteForm.permission
            })
        )

        await Promise.all(invitePromises)
        ElMessage.success(`成功邀请 ${inviteForm.selectedUsers.length} 名成员`)

        // 重置表单
        resetInviteForm()

        // 重新获取成员列表
        await fetchMembers()
    } catch (error: any) {
        ElMessage.error('邀请失败，请稍后重试')
    } finally {
        inviteLoading.value = false
    }
}

// 简单邀请（更新逻辑）
const handleSimpleInvite = async () => {
    if (!simpleInviteFormRef.value || !props.projectId) return

    try {
        await simpleInviteFormRef.value.validate()
        
        // 确保选择了警号并设置了对应的username
        if (!simpleInviteForm.username) {
            const selectedUser = policeNumberOptions.value.find(
                option => option.value === simpleInviteForm.police_number
            )
            if (selectedUser) {
                simpleInviteForm.username = selectedUser.username
            } else {
                ElMessage.error('请选择有效的警号')
                return
            }
        }
        
        simpleInviteLoading.value = true

        await projectStore.inviteMember(props.projectId, {
            username: simpleInviteForm.username,
            permission: simpleInviteForm.permission
        })

        ElMessage.success('成员邀请成功')
        resetSimpleInviteForm()

        // 重新获取成员列表
        await fetchMembers()
    } catch (error: any) {
        if (error.response?.data?.username) {
            ElMessage.error('用户不存在')
        } else {
            ElMessage.error('邀请失败，请稍后重试')
        }
    } finally {
        simpleInviteLoading.value = false
    }
}

// 重置邀请表单
const resetInviteForm = () => {
    inviteForm.department = ''
    inviteForm.selectedUsers = []
    inviteForm.permission = 'read'
    departmentUsers.value = []
    inviteFormRef.value?.clearValidate()
}

const handleInvite = handleBatchInvite

const handlePermissionChange = async (member: ProjectMember, newPermission: string) => {
    if (!props.projectId) return

    try {
        await projectStore.updateMemberPermission(
            props.projectId,
            member.user.username,
            newPermission
        )

        ElMessage.success('权限更新成功')
        await fetchMembers()
    } catch (error) {
        ElMessage.error('权限更新失败')
    }
}

const handleRemoveMember = async (member: ProjectMember) => {
    if (!props.projectId) return

    try {
        await ElMessageBox.confirm(
            `确定要移除成员 "${member.user.real_name || member.user.username}" 吗？`,
            '确认移除',
            {
                confirmButtonText: '确定',
                cancelButtonText: '取消',
                type: 'warning'
            }
        )

        await projectStore.removeMember(props.projectId, member.user.username)
        ElMessage.success('成员移除成功')
        await fetchMembers()
    } catch (error) {
        // 用户取消操作
    }
}

const canEditPermission = (member: ProjectMember) => {
    // 当前用户必须是管理员，且不能修改项目创建者的权限
    const currentMember = members.value.find(m => m.user.username === currentUser.value?.username)
    return currentMember?.permission === 'admin' &&
        member.user.username !== projectStore.currentProject?.creator.username
}

const canRemoveMember = (member: ProjectMember) => {
    // 当前用户必须是管理员，且不能移除项目创建者
    const currentMember = members.value.find(m => m.user.username === currentUser.value?.username)
    return currentMember?.permission === 'admin' &&
        member.user.username !== projectStore.currentProject?.creator.username
}

const getPermissionText = (permission: string) => {
    const map = {
        read: '只读',
        edit: '编辑',
        admin: '管理员'
    }
    return map[permission as keyof typeof map] || permission
}

const getPermissionTagType = (permission: string) => {
    const map = {
        read: '',
        edit: 'warning',
        admin: 'danger'
    }
    return map[permission as keyof typeof map] || ''
}

const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleString('zh-CN')
}

const getUnitDisplay = (department: string) => {
    const unitMap: { [key: string]: string } = {
        'direct': '市局直属部门',
        'tianyuan': '天元分局',
        'lusong': '芦淞分局',
        'hetang': '荷塘分局',
        'shifeng': '石峰分局',
        'dongjiabai': '董家塅分局',
        'kaifaqu': '经开区分局',
        'lukou': '渌口分局',
        'liling': '醴陵市公安局',
        'youxian': '攸县公安局',
        'chaling': '茶陵县公安局',
        'yanling': '炎陵县公安局'
    }
    return unitMap[department] || department
}

// 处理真实姓名输入变化
const handleRealNameChange = async (realName: string) => {
    if (!realName.trim()) {
        departmentOptions.value = []
        policeNumberOptions.value = []
        foundUsers.value = []
        simpleInviteForm.department = ''
        simpleInviteForm.police_number = ''
        simpleInviteForm.username = ''
        return
    }

    searchLoading.value = true
    try {
        const response = await userAPI.searchUsersByRealName(realName.trim())
        foundUsers.value = response.data.users
        
        // 提取单位选项
        const departments = [...new Set(foundUsers.value.map(user => user.department))]
        departmentOptions.value = departments.map(dept => ({
            value: dept,
            label: getUnitDisplay(dept)
        }))
        
        // 清空之前的选择
        simpleInviteForm.department = ''
        simpleInviteForm.police_number = ''
        simpleInviteForm.username = ''
        policeNumberOptions.value = []
        
        // 如果只有一个单位，自动选择
        if (departmentOptions.value.length === 1) {
            simpleInviteForm.department = departmentOptions.value[0].value
            handleDepartmentSelectChange(simpleInviteForm.department)
        }
        
    } catch (error: any) {
        if (error.response?.status === 404) {
            ElMessage.warning('此人未注册')
            departmentOptions.value = []
            policeNumberOptions.value = []
            foundUsers.value = []
        } else {
            ElMessage.error('查询用户失败')
        }
        simpleInviteForm.department = ''
        simpleInviteForm.police_number = ''
        simpleInviteForm.username = ''
    } finally {
        searchLoading.value = false
    }
}

// 处理单位选择变化
const handleDepartmentSelectChange = (department: string) => {
    if (!department) {
        policeNumberOptions.value = []
        simpleInviteForm.police_number = ''
        simpleInviteForm.username = ''
        return
    }
    
    // 根据选择的单位筛选警号选项
    const usersInDepartment = foundUsers.value.filter(user => user.department === department)
    policeNumberOptions.value = usersInDepartment.map(user => ({
        value: user.police_number,
        label: `${user.police_number} (${user.real_name})`,
        username: user.username
    }))
    
    // 清空之前的警号选择
    simpleInviteForm.police_number = ''
    simpleInviteForm.username = ''
    
    // 如果只有一个警号，自动选择
    if (policeNumberOptions.value.length === 1) {
        simpleInviteForm.police_number = policeNumberOptions.value[0].value
        simpleInviteForm.username = policeNumberOptions.value[0].username
    }
}

// 处理警号选择变化
const handlePoliceNumberChange = (policeNumber: string) => {
    if (!policeNumber) {
        simpleInviteForm.username = ''
        return
    }
    
    const selectedUser = policeNumberOptions.value.find(option => option.value === policeNumber)
    if (selectedUser) {
        simpleInviteForm.username = selectedUser.username
    }
}

// 重置简单邀请表单
const resetSimpleInviteForm = () => {
    simpleInviteForm.real_name = ''
    simpleInviteForm.department = ''
    simpleInviteForm.police_number = ''
    simpleInviteForm.username = ''
    simpleInviteForm.permission = 'read'
    departmentOptions.value = []
    policeNumberOptions.value = []
    foundUsers.value = []
    simpleInviteFormRef.value?.clearValidate()
}

const handleClose = () => {
    dialogVisible.value = false
    resetInviteForm()
    resetSimpleInviteForm()
}
</script>

<style scoped>
.members-management {
    display: flex;
    flex-direction: column;
    gap: 20px;
}

.invite-card,
.members-card {
    border: 1px solid #e4e7ed;
}

.card-header {
    font-weight: 600;
    color: #303133;
}

.user-info .real-name {
    font-weight: 500;
    color: #303133;
}

.user-info .username {
    font-size: 12px;
    color: #909399;
    margin-top: 2px;
}

.department-text {
    color: #606266;
    font-size: 14px;
}

.no-action {
    color: #c0c4cc;
}

.loading-container {
    padding: 20px 0;
}

.dialog-footer {
    display: flex;
    justify-content: center;
}
</style>
