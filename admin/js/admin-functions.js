// 管理后台扩展功能
class TokenAdminExtended extends TokenAdmin {
    
    // 渲染分页
    renderPagination(pagination) {
        const container = document.getElementById('pagination');
        
        container.innerHTML = `
            <div class="flex items-center justify-between">
                <div class="text-sm text-gray-700">
                    显示第 ${(pagination.page - 1) * pagination.limit + 1} 到 
                    ${Math.min(pagination.page * pagination.limit, pagination.total)} 条，
                    共 ${pagination.total} 条记录
                </div>
                <div class="flex space-x-1">
                    <button ${pagination.page <= 1 ? 'disabled' : ''} 
                            onclick="tokenAdmin.changePage(${pagination.page - 1})"
                            class="px-3 py-2 text-sm bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed">
                        上一页
                    </button>
                    <span class="px-3 py-2 text-sm bg-blue-50 border border-blue-200 rounded-md">
                        ${pagination.page} / ${pagination.totalPages}
                    </span>
                    <button ${pagination.page >= pagination.totalPages ? 'disabled' : ''} 
                            onclick="tokenAdmin.changePage(${pagination.page + 1})"
                            class="px-3 py-2 text-sm bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed">
                        下一页
                    </button>
                </div>
            </div>
        `;
    }

    // 处理筛选器变化
    handleFilterChange(type, value) {
        this.filters[type] = value;
        this.currentPage = 1;
        this.loadTokens();
    }

    // 切换页面
    changePage(page) {
        this.currentPage = page;
        this.loadTokens();
    }

    // 打开代币模态框
    openTokenModal(token = null) {
        const modal = document.getElementById('tokenModal');
        const title = document.getElementById('modalTitle');
        const form = document.getElementById('tokenForm');
        
        if (token) {
            title.textContent = '编辑代币';
            this.fillTokenForm(token);
        } else {
            title.textContent = '添加代币';
            form.reset();
            document.getElementById('tokenId').value = '';
        }
        
        modal.classList.remove('hidden');
    }

    // 关闭代币模态框
    closeTokenModal() {
        document.getElementById('tokenModal').classList.add('hidden');
    }

    // 填充代币表单
    fillTokenForm(token) {
        document.getElementById('tokenId').value = token.id;
        document.getElementById('tokenName').value = token.name;
        document.getElementById('tokenSymbol').value = token.symbol;
        document.getElementById('contractAddress').value = token.contract_address;
        document.getElementById('decimals').value = token.decimals;
        document.getElementById('displayOrder').value = token.display_order || 0;
        document.getElementById('iconUrl').value = token.icon_url || '';
        document.getElementById('description').value = token.description || '';
        document.getElementById('officialWebsite').value = token.official_website || '';
        document.getElementById('isNative').checked = token.is_native;
    }

    // 处理代币表单提交
    async handleTokenSubmit(e) {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        const tokenData = {
            name: formData.get('name'),
            symbol: formData.get('symbol'),
            contract_address: formData.get('contract_address'),
            decimals: parseInt(formData.get('decimals')),
            display_order: parseInt(formData.get('display_order') || 0),
            icon_url: formData.get('icon_url') || null,
            description: formData.get('description') || null,
            official_website: formData.get('official_website') || null,
            is_native: formData.has('is_native')
        };

        const tokenId = formData.get('id');
        const isEdit = tokenId && tokenId !== '';

        try {
            this.showLoading();
            
            const url = isEdit ? `${this.baseURL}/tokens/${tokenId}` : `${this.baseURL}/tokens`;
            const method = isEdit ? 'PUT' : 'POST';
            
            const response = await fetch(url, {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    ...this.getAuthHeaders()
                },
                body: JSON.stringify(tokenData)
            });

            const result = await response.json();

            if (result.success) {
                this.showMessage(isEdit ? '代币更新成功' : '代币添加成功', 'success');
                this.closeTokenModal();
                this.loadData();
            } else {
                this.showMessage(result.message || '操作失败', 'error');
            }
        } catch (error) {
            console.error('Token submit error:', error);
            this.showMessage('操作失败，请检查网络连接', 'error');
        } finally {
            this.hideLoading();
        }
    }

    // 编辑代币
    async editToken(id) {
        try {
            const response = await fetch(`${this.baseURL}/tokens/${id}`, {
                headers: this.getAuthHeaders()
            });

            if (response.ok) {
                const result = await response.json();
                this.openTokenModal(result.data);
            } else {
                this.showMessage('获取代币信息失败', 'error');
            }
        } catch (error) {
            console.error('Failed to get token:', error);
            this.showMessage('获取代币信息失败', 'error');
        }
    }

    // 切换代币状态
    async toggleToken(id) {
        if (!confirm('确定要切换代币状态吗？')) return;

        try {
            this.showLoading();
            
            const response = await fetch(`${this.baseURL}/tokens/${id}/toggle`, {
                method: 'PATCH',
                headers: this.getAuthHeaders()
            });

            const result = await response.json();

            if (result.success) {
                this.showMessage(result.message, 'success');
                this.loadData();
            } else {
                this.showMessage(result.message || '操作失败', 'error');
            }
        } catch (error) {
            console.error('Failed to toggle token:', error);
            this.showMessage('操作失败', 'error');
        } finally {
            this.hideLoading();
        }
    }

    // 删除代币
    async deleteToken(id) {
        if (!confirm('确定要删除这个代币吗？此操作将禁用该代币。')) return;

        try {
            this.showLoading();
            
            const response = await fetch(`${this.baseURL}/tokens/${id}`, {
                method: 'DELETE',
                headers: this.getAuthHeaders()
            });

            const result = await response.json();

            if (result.success) {
                this.showMessage('代币已禁用', 'success');
                this.loadData();
            } else {
                this.showMessage(result.message || '删除失败', 'error');
            }
        } catch (error) {
            console.error('Failed to delete token:', error);
            this.showMessage('删除失败', 'error');
        } finally {
            this.hideLoading();
        }
    }
}

// 扩展现有的tokenAdmin实例，而不是重新创建
Object.setPrototypeOf(tokenAdmin, TokenAdminExtended.prototype);
Object.assign(tokenAdmin, new TokenAdminExtended());

// 重新绑定事件（确保DOM元素已加载）
document.addEventListener('DOMContentLoaded', function() {
    if (tokenAdmin && typeof tokenAdmin.bindEvents === 'function') {
        tokenAdmin.bindEvents();
    }
});