from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UserViewSet, get_csrf_token, verify_identity_api, supplement_face_api, 
    admin_login_api, test_auth_status, change_password_api,
    forgot_password_verify_identity_api, forgot_password_face_verify_api,
    reset_password_api, admin_reset_password_api
)

router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')

urlpatterns = [
    path('csrf/', get_csrf_token, name='csrf'),
    path('test-auth/', test_auth_status, name='test_auth_status'),
    # 专用API端点（必须放在router之前，以避免被ViewSet路由拦截）
    path('users/verify-identity-supplement/', verify_identity_api, name='verify_identity_api'),
    path('users/supplement-face/', supplement_face_api, name='supplement_face_api'),
    path('users/admin-login/', admin_login_api, name='admin_login_api'),
    path('users/change-password/', change_password_api, name='change_password_api'),
    # 忘记密码相关API
    path('users/forgot-password/verify-identity/', forgot_password_verify_identity_api, name='forgot_password_verify_identity'),
    path('users/forgot-password/face-verify/', forgot_password_face_verify_api, name='forgot_password_face_verify'),
    path('users/reset-password/', reset_password_api, name='reset_password'),
    path('users/admin-reset-password/', admin_reset_password_api, name='admin_reset_password'),
    path('users/by-police-number/<str:police_number>/', UserViewSet.as_view({'get': 'get_by_police_number'}), name='get_user_by_police_number'),
    path('', include(router.urls)),
]
