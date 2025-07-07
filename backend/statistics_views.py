from django.db.models import Count, Q
from django.http import JsonResponse
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from projects.models import Project, CaseAttachment
from mindmaps.models import MindMapNode
from decimal import Decimal

User = get_user_model()

@api_view(['GET'])
@permission_classes([AllowAny])
def public_statistics(request):
    """获取公开的统计数据"""
    try:
        # 按金额区间统计案件数量
        amount_10_50 = Project.objects.filter(
            case_amount__gte=Decimal('100000'),  # 10万
            case_amount__lt=Decimal('500000')    # 50万
        ).count()
        
        amount_50_100 = Project.objects.filter(
            case_amount__gte=Decimal('500000'),   # 50万
            case_amount__lt=Decimal('1000000')   # 100万
        ).count()
        
        amount_100_plus = Project.objects.filter(
            case_amount__gte=Decimal('1000000')  # 100万以上
        ).count()
        
        # 统计数据
        stats = {
            'total_cases': Project.objects.count(),
            'total_nodes': MindMapNode.objects.filter(is_system_default=False).count(),
            'total_users': User.objects.count(),
            'amount_10_50': amount_10_50,
            'amount_50_100': amount_50_100,
            'amount_100_plus': amount_100_plus
        }
        
        return Response(stats)
    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([AllowAny])
def department_statistics(request):
    """获取各单位的统计数据"""
    try:
        departments_data = []
        
        # 获取所有部门选择
        for dept_code, dept_name in User.DEPARTMENT_CHOICES:
            # 获取该部门的用户
            dept_users = User.objects.filter(department=dept_code)
            
            # 获取该部门创建的项目
            dept_projects = Project.objects.filter(creator__in=dept_users)
            
            # 统计该部门各金额区间的案件数量
            dept_amount_10_50 = dept_projects.filter(
                case_amount__gte=Decimal('100000'),
                case_amount__lt=Decimal('500000')
            ).count()
            
            dept_amount_50_100 = dept_projects.filter(
                case_amount__gte=Decimal('500000'),
                case_amount__lt=Decimal('1000000')
            ).count()
            
            dept_amount_100_plus = dept_projects.filter(
                case_amount__gte=Decimal('1000000')
            ).count()
            
            # 统计节点数量
            total_nodes = 0
            total_attachments = 0
            cases_data = []
            
            for project in dept_projects:
                # 统计该项目的节点数量（排除系统默认节点）
                project_nodes = MindMapNode.objects.filter(
                    project=project, 
                    is_system_default=False
                ).count()
                total_nodes += project_nodes
                
                # 统计该项目的附件数量
                project_attachments = CaseAttachment.objects.filter(project=project).count()
                total_attachments += project_attachments
                
                cases_data.append({
                    'id': project.id,
                    'name': project.name,
                    'description': project.case_summary,
                    'node_count': project_nodes,
                    'attachment_count': project_attachments,
                    'case_amount': float(project.case_amount) if project.case_amount else None,
                    'created_at': project.created_at.isoformat()
                })
            
            department_info = {
                'name': dept_code,
                'display_name': dept_name,
                'case_count': dept_projects.count(),
                'node_count': total_nodes,
                'attachment_count': total_attachments,
                'amount_10_50': dept_amount_10_50,
                'amount_50_100': dept_amount_50_100,
                'amount_100_plus': dept_amount_100_plus,
                'cases': cases_data
            }
            
            departments_data.append(department_info)
        
        return Response(departments_data)
    except Exception as e:
        return Response({'error': str(e)}, status=500)
