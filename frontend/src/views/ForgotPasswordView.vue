<template>
    <div class="forgot-password-container">
        <el-card class="forgot-password-card">
            <template #header>
                <div class="card-header">
                    <h2>找回密码</h2>
                    <p v-if="currentStep === 'identity'">第一步：身份验证</p>
                    <p v-else-if="currentStep === 'method'">第二步：选择找回方式</p>
                    <p v-else-if="currentStep === 'face'">第三步：人脸识别验证</p>
                    <p v-else-if="currentStep === 'reset'">第四步：设置新密码</p>
                    <p v-else-if="currentStep === 'admin'">管理员重置密码</p>
                </div>
            </template>

            <!-- 第一步：身份验证 -->
            <div v-if="currentStep === 'identity'">
                <el-form ref="identityFormRef" :model="identityForm" :rules="identityRules" label-width="100px">
                    <el-form-item label="警号" prop="police_number">
                        <el-input v-model="identityForm.police_number" placeholder="请输入警号" clearable />
                    </el-form-item>

                    <el-form-item label="真实姓名" prop="real_name">
                        <el-input v-model="identityForm.real_name" placeholder="请输入真实姓名" clearable />
                    </el-form-item>

                    <el-form-item label="手机号" prop="phone_number">
                        <el-input v-model="identityForm.phone_number" placeholder="请输入手机号" clearable />
                    </el-form-item>

                    <el-form-item>
                        <el-alert title="提示" type="info" show-icon :closable="false" style="margin-bottom: 20px">
                            <p>请输入正确的身份信息进行验证，验证通过后可选择找回方式</p>
                        </el-alert>
                    </el-form-item>

                    <el-form-item>
                        <el-button type="primary" :loading="loading" @click="verifyIdentity" style="width: 100%">
                            验证身份
                        </el-button>
                    </el-form-item>

                    <el-form-item>
                        <div class="back-to-login">
                            <router-link to="/login" class="back-link">
                                ← 返回登录
                            </router-link>
                        </div>
                    </el-form-item>
                </el-form>
            </div>

            <!-- 第二步：选择找回方式 -->
            <div v-if="currentStep === 'method' && verifiedUser">
                <div class="method-selection">
                    <el-alert title="身份验证成功" type="success" show-icon :closable="false" style="margin-bottom: 20px">
                        <p>用户：{{ verifiedUser.real_name }} ({{ verifiedUser.police_number }})</p>
                    </el-alert>

                    <h3 style="margin-bottom: 20px; text-align: center;">请选择密码找回方式</h3>

                    <div class="method-cards">
                        <el-card class="method-card" :class="{ 'method-disabled': !canUseFaceRecognition }"
                            @click="selectMethod('face')" :body-style="{ padding: '30px' }">
                            <div class="method-content">
                                <el-icon :size="40" color="#409EFF">
                                    <Avatar />
                                </el-icon>
                                <h4>人脸识别找回</h4>
                                <p>通过人脸识别验证身份后重置密码</p>
                                <p v-if="!canUseFaceRecognition" class="disabled-text">
                                    (您尚未录入人脸信息，无法使用此方式)
                                </p>
                            </div>
                        </el-card>

                        <el-card class="method-card" @click="selectMethod('admin')" :body-style="{ padding: '30px' }">
                            <div class="method-content">
                                <el-icon :size="40" color="#E6A23C">
                                    <UserFilled />
                                </el-icon>
                                <h4>管理员重置</h4>
                                <p>由管理员重置密码为初始密码</p>
                                <p class="tip-text">初始密码格式：user + 您的警号</p>
                            </div>
                        </el-card>
                    </div>

                    <div style="text-align: center; margin-top: 20px;">
                        <el-button @click="goBack">
                            ← 返回上一步
                        </el-button>
                    </div>
                </div>
            </div>

            <!-- 第三步：人脸识别验证 -->
            <div v-if="currentStep === 'face'">
                <div class="face-verification-section">
                    <el-alert title="人脸识别验证" type="warning" show-icon :closable="false" style="margin-bottom: 20px">
                        <p>请对准摄像头进行人脸识别，验证成功后可设置新密码</p>
                    </el-alert>

                    <div class="camera-container">
                        <video ref="videoRef" autoplay playsinline
                            :style="{ display: showCamera ? 'block' : 'none' }"></video>
                        <canvas ref="canvasRef" :style="{ display: showCamera ? 'none' : 'block' }"></canvas>

                        <!-- 识别状态指示器 -->
                        <div v-if="faceRecognizing" class="recognition-indicator">
                            <el-progress type="circle" :percentage="Math.round((20 - recognitionCountdown) / 20 * 100)"
                                :color="recognitionCountdown > 5 ? '#409EFF' : '#F56C6C'" :width="80">
                                <template #default="{ percentage }">
                                    <span class="countdown-text">{{ recognitionCountdown }}s</span>
                                </template>
                            </el-progress>
                        </div>
                    </div>

                    <div class="face-controls">
                        <el-button v-if="!cameraStarted" type="primary" @click="startCamera" :loading="cameraLoading">
                            开启摄像头
                        </el-button>

                        <div v-else class="face-buttons">
                            <el-button v-if="!faceRecognizing" type="success" @click="startFaceVerification"
                                :loading="verifying">
                                开始人脸验证
                            </el-button>

                            <el-button v-if="faceRecognizing" type="warning" @click="stopFaceVerification">
                                停止验证
                            </el-button>

                            <el-button @click="stopCamera">
                                关闭摄像头
                            </el-button>
                        </div>
                    </div>

                    <div style="text-align: center; margin-top: 20px;">
                        <el-button @click="goBack">
                            ← 返回选择方式
                        </el-button>
                    </div>
                </div>
            </div>

            <!-- 第四步：设置新密码 -->
            <div v-if="currentStep === 'reset'">
                <el-form ref="resetFormRef" :model="resetForm" :rules="resetRules" label-width="100px">
                    <el-alert title="验证成功" type="success" show-icon :closable="false" style="margin-bottom: 20px">
                        <p>身份验证通过，现在可以设置新密码</p>
                    </el-alert>

                    <el-form-item label="新密码" prop="new_password">
                        <el-input v-model="resetForm.new_password" type="password" placeholder="请输入新密码" show-password
                            clearable />
                    </el-form-item>

                    <el-form-item label="确认密码" prop="confirm_password">
                        <el-input v-model="resetForm.confirm_password" type="password" placeholder="请再次输入新密码"
                            show-password clearable />
                    </el-form-item>

                    <el-form-item>
                        <el-alert title="密码要求" type="info" show-icon :closable="false">
                            <p>• 密码长度至少6位</p>
                            <p>• 建议包含字母、数字和特殊字符</p>
                        </el-alert>
                    </el-form-item>

                    <el-form-item>
                        <el-button type="primary" :loading="loading" @click="resetPassword" style="width: 100%">
                            重置密码
                        </el-button>
                    </el-form-item>
                </el-form>
            </div>

            <!-- 管理员重置密码 -->
            <div v-if="currentStep === 'admin' && verifiedUser">
                <div class="admin-reset-section">
                    <el-alert title="管理员重置密码" type="warning" show-icon :closable="false" style="margin-bottom: 20px">
                        <p>请输入管理员凭据来重置用户密码</p>
                        <p>用户信息：{{ verifiedUser.real_name }} ({{ verifiedUser.police_number }})</p>
                        <p><strong>重置后的初始密码：user{{ verifiedUser.police_number }}</strong></p>
                    </el-alert>

                    <el-form ref="adminFormRef" :model="adminForm" :rules="adminRules" label-width="100px"
                        style="max-width: 400px; margin: 0 auto;">
                        <el-form-item label="管理员账号" prop="admin_username">
                            <el-input v-model="adminForm.admin_username" placeholder="请输入管理员用户名" clearable />
                        </el-form-item>
                        <el-form-item label="管理员密码" prop="admin_password">
                            <el-input v-model="adminForm.admin_password" type="password" placeholder="请输入管理员密码"
                                clearable show-password />
                        </el-form-item>
                    </el-form>

                    <div style="text-align: center; margin: 30px 0;">
                        <el-button type="danger" :loading="loading" @click="adminResetPassword" size="large">
                            确认重置密码
                        </el-button>
                    </div>

                    <div style="text-align: center;">
                        <el-button @click="goBack">
                            ← 返回选择方式
                        </el-button>
                    </div>
                </div>
            </div>
        </el-card>
    </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Avatar, UserFilled } from '@element-plus/icons-vue'
import { userAPI } from '@/api'
import { useRouter } from 'vue-router'

const router = useRouter()

// 当前步骤
const currentStep = ref<'identity' | 'method' | 'face' | 'reset' | 'admin'>('identity')

// 加载状态
const loading = ref(false)
const cameraLoading = ref(false)
const verifying = ref(false)

// 身份验证表单
const identityForm = reactive({
    police_number: '',
    real_name: '',
    phone_number: ''
})

const identityRules = {
    police_number: [
        { required: true, message: '请输入警号', trigger: 'blur' }
    ],
    real_name: [
        { required: true, message: '请输入真实姓名', trigger: 'blur' }
    ],
    phone_number: [
        { required: true, message: '请输入手机号', trigger: 'blur' },
        { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号', trigger: 'blur' }
    ]
}

// 重置密码表单
const resetForm = reactive({
    new_password: '',
    confirm_password: ''
})

const resetRules = {
    new_password: [
        { required: true, message: '请输入新密码', trigger: 'blur' },
        { min: 6, message: '密码长度至少6位', trigger: 'blur' }
    ],
    confirm_password: [
        { required: true, message: '请确认密码', trigger: 'blur' },
        {
            validator: (rule: any, value: string, callback: Function) => {
                if (value !== resetForm.new_password) {
                    callback(new Error('两次输入的密码不一致'))
                } else {
                    callback()
                }
            },
            trigger: 'blur'
        }
    ]
}

// 管理员表单
const adminForm = reactive({
    admin_username: '',
    admin_password: ''
})

const adminRules = {
    admin_username: [
        { required: true, message: '请输入管理员用户名', trigger: 'blur' }
    ],
    admin_password: [
        { required: true, message: '请输入管理员密码', trigger: 'blur' }
    ]
}

// 验证通过的用户信息
const verifiedUser = ref<any>(null)
const faceVerifyToken = ref('')
const resetToken = ref('')
const canUseFaceRecognition = ref(true)

// 表单引用
const identityFormRef = ref()
const resetFormRef = ref()
const adminFormRef = ref()

// 摄像头相关
const videoRef = ref<HTMLVideoElement>()
const canvasRef = ref<HTMLCanvasElement>()
const cameraStarted = ref(false)
const showCamera = ref(true)
const faceRecognizing = ref(false)
const recognitionCountdown = ref(20)
let recognitionTimer: NodeJS.Timeout | null = null
let mediaStream: MediaStream | null = null

// 人脸识别相关
let faceapi: any = null

// 身份验证
const verifyIdentity = async () => {
    if (!identityFormRef.value) return

    try {
        await identityFormRef.value.validate()
        loading.value = true

        const response = await userAPI.forgotPasswordVerifyIdentity(identityForm)

        verifiedUser.value = response.data.user
        faceVerifyToken.value = response.data.token
        canUseFaceRecognition.value = response.data.has_face_data

        currentStep.value = 'method'
        ElMessage.success('身份验证成功')
    } catch (error: any) {
        ElMessage.error(error.response?.data?.error || '身份验证失败')
    } finally {
        loading.value = false
    }
}

// 选择找回方式
const selectMethod = (method: 'face' | 'admin') => {
    if (method === 'face' && !canUseFaceRecognition.value) {
        ElMessage.warning('您尚未录入人脸信息，无法使用人脸识别找回')
        return
    }

    if (method === 'face') {
        currentStep.value = 'face'
    } else {
        currentStep.value = 'admin'
    }
}

// 返回上一步
const goBack = () => {
    if (currentStep.value === 'method') {
        currentStep.value = 'identity'
    } else if (currentStep.value === 'face' || currentStep.value === 'admin') {
        currentStep.value = 'method'
    } else if (currentStep.value === 'reset') {
        currentStep.value = 'method'
    }
}

// 启动摄像头
const startCamera = async () => {
    try {
        cameraLoading.value = true

        mediaStream = await navigator.mediaDevices.getUserMedia({
            video: { width: 640, height: 480 }
        })

        if (videoRef.value) {
            videoRef.value.srcObject = mediaStream
            await videoRef.value.play()
            cameraStarted.value = true
            showCamera.value = true
        }
    } catch (error) {
        ElMessage.error('无法开启摄像头，请检查设备权限')
    } finally {
        cameraLoading.value = false
    }
}

// 停止摄像头
const stopCamera = () => {
    if (mediaStream) {
        mediaStream.getTracks().forEach(track => track.stop())
        mediaStream = null
    }
    cameraStarted.value = false
    showCamera.value = true
    stopFaceVerification()
}

// 开始人脸验证
const startFaceVerification = () => {
    faceRecognizing.value = true
    recognitionCountdown.value = 20

    recognitionTimer = setInterval(() => {
        recognitionCountdown.value--
        if (recognitionCountdown.value <= 0) {
            performFaceVerification()
        }
    }, 1000)
}

// 停止人脸验证
const stopFaceVerification = () => {
    faceRecognizing.value = false
    if (recognitionTimer) {
        clearInterval(recognitionTimer)
        recognitionTimer = null
    }
}

// 执行人脸验证
const performFaceVerification = async () => {
    try {
        if (!videoRef.value || !canvasRef.value) return

        verifying.value = true
        stopFaceVerification()

        // 获取当前视频帧
        const canvas = canvasRef.value
        const ctx = canvas.getContext('2d')
        if (!ctx) return

        canvas.width = videoRef.value.videoWidth
        canvas.height = videoRef.value.videoHeight
        ctx.drawImage(videoRef.value, 0, 0)
        showCamera.value = false

        // 这里应该集成真正的人脸识别逻辑
        // 为了演示，我们模拟人脸编码数据
        const mockFaceEncodings = [
            Array.from({ length: 128 }, () => Math.random() * 2 - 1)
        ]

        const response = await userAPI.forgotPasswordFaceVerify({
            token: faceVerifyToken.value,
            face_encodings: mockFaceEncodings
        })

        resetToken.value = response.data.token
        currentStep.value = 'reset'
        ElMessage.success('人脸验证成功')

        // 停止摄像头
        stopCamera()
    } catch (error: any) {
        ElMessage.error(error.response?.data?.error || '人脸验证失败')
        showCamera.value = true
    } finally {
        verifying.value = false
    }
}

// 重置密码
const resetPassword = async () => {
    if (!resetFormRef.value) return

    try {
        await resetFormRef.value.validate()
        loading.value = true

        await userAPI.resetPassword({
            token: resetToken.value,
            new_password: resetForm.new_password
        })

        ElMessage.success('密码重置成功')

        // 显示成功提示并跳转到登录页
        await ElMessageBox.alert('密码重置成功，请使用新密码登录', '成功', {
            confirmButtonText: '去登录',
            type: 'success'
        })

        router.push('/login')
    } catch (error: any) {
        ElMessage.error(error.response?.data?.error || '密码重置失败')
    } finally {
        loading.value = false
    }
}

// 管理员重置密码
const adminResetPassword = async () => {
    if (!adminFormRef.value) return

    try {
        // 验证管理员表单
        await adminFormRef.value.validate()

        const confirmResult = await ElMessageBox.confirm(
            `确认要重置用户 ${verifiedUser.value.real_name} (${verifiedUser.value.police_number}) 的密码吗？`,
            '确认重置',
            {
                confirmButtonText: '确认重置',
                cancelButtonText: '取消',
                type: 'warning'
            }
        )

        if (confirmResult === 'confirm') {
            loading.value = true

            await userAPI.adminResetPassword({
                police_number: verifiedUser.value.police_number,
                admin_username: adminForm.admin_username,
                admin_password: adminForm.admin_password
            })

            ElMessage.success('密码重置成功')

            // 显示成功提示并跳转到登录页
            await ElMessageBox.alert(
                `密码已重置为初始密码：user${verifiedUser.value.police_number}\n请使用此密码登录并及时修改`,
                '重置成功',
                {
                    confirmButtonText: '去登录',
                    type: 'success'
                }
            )

            router.push('/login')
        }
    } catch (error: any) {
        if (error !== 'cancel') {
            ElMessage.error(error.response?.data?.error || '密码重置失败')
        }
    } finally {
        loading.value = false
    }
}

// 清理资源
onUnmounted(() => {
    stopCamera()
})
</script>

<style scoped>
.forgot-password-container {
    min-height: 100vh;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
}

.forgot-password-card {
    width: 100%;
    max-width: 600px;
    border-radius: 12px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
    border: none;
}

.card-header {
    text-align: center;
    margin-bottom: 10px;
}

.card-header h2 {
    margin: 0 0 10px 0;
    color: #333;
    font-weight: 600;
}

.card-header p {
    margin: 0;
    color: #666;
    font-size: 14px;
}

.method-selection {
    text-align: center;
}

.method-cards {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    margin: 20px 0;
}

.method-card {
    cursor: pointer;
    transition: all 0.3s ease;
    border-radius: 12px;
}

.method-card:hover:not(.method-disabled) {
    transform: translateY(-4px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
}

.method-disabled {
    opacity: 0.6;
    cursor: not-allowed;
}

.method-content {
    text-align: center;
}

.method-content h4 {
    margin: 15px 0 10px 0;
    color: #333;
}

.method-content p {
    margin: 5px 0;
    color: #666;
    font-size: 14px;
}

.disabled-text {
    color: #F56C6C !important;
    font-weight: 500;
}

.tip-text {
    color: #E6A23C !important;
    font-weight: 500;
}

.face-verification-section {
    text-align: center;
}

.camera-container {
    position: relative;
    margin: 20px auto;
    width: 320px;
    height: 240px;
    border: 2px solid #ddd;
    border-radius: 8px;
    overflow: hidden;
    background: #f5f5f5;
}

.camera-container video,
.camera-container canvas {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.recognition-indicator {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: rgba(255, 255, 255, 0.9);
    border-radius: 50%;
    padding: 20px;
}

.countdown-text {
    font-size: 12px;
    font-weight: bold;
}

.face-controls {
    margin: 20px 0;
}

.face-buttons {
    display: flex;
    gap: 10px;
    justify-content: center;
    flex-wrap: wrap;
}

.admin-reset-section {
    text-align: center;
}

.admin-info {
    background: #f8f9fa;
    padding: 20px;
    border-radius: 8px;
    margin: 20px 0;
    border-left: 4px solid #E6A23C;
}

.admin-info p {
    margin: 5px 0;
    color: #666;
}

.back-to-login {
    text-align: center;
    margin-top: 10px;
}

.back-link {
    color: #409EFF;
    text-decoration: none;
    font-size: 14px;
}

.back-link:hover {
    text-decoration: underline;
}

:deep(.el-form-item__label) {
    font-weight: 500;
}

:deep(.el-input__wrapper) {
    border-radius: 8px;
}

:deep(.el-card__header) {
    background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
    border-bottom: 1px solid #ebeef5;
}
</style>
