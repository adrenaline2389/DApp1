// 代币管理后台 JavaScript
class TokenAdmin {
    constructor() {
        this.baseURL = 'http://localhost:3001/api';
        this.token = localStorage.getItem('adminToken');
        this.currentPage = 1;
        this.pageSize = 10;
        this.filters = {
            status: 'all',
            type: 'all'
        };
        
        this.init();
    }

    // 初始化
    init() {
        this.bindEvents();
        this.checkAuth();
    }

    // 绑定事件
    bindEvents() {
        // 登录表单
        document.getElementById('loginForm').addEventListener('submit', (e) => this.handleLogin(e));
        
        // 登出按钮
        document.getElementById('logoutBtn').addEventListener('click', () => this.handleLogout());
        
        // 添加代币按钮
        document.getElementById('addTokenBtn').addEventListener('click', () => this.openTokenModal());
        
        // 模态框关闭
        document.getElementById('closeModalBtn').addEventListener('click', () => this.closeTokenModal());
        document.getElementById('cancelBtn').addEventListener('click', () => this.closeTokenModal());
        
        // 代币表单提交
        document.getElementById('tokenForm').addEventListener('submit', (e) => this.handleTokenSubmit(e));
        
        // 筛选器
        document.getElementById('statusFilter').addEventListener('change', (e) => this.handleFilterChange('status', e.target.value));
        document.getElementById('typeFilter').addEventListener('change', (e) => this.handleFilterChange('type', e.target.value));
        
        // 刷新按钮
        document.getElementById('refreshBtn').addEventListener('click', () => this.loadTokens());
        
        // 代币操作按钮事件委托
        document.addEventListener('click', (e) => {
            if (e.target.closest('.action-btn')) {
                const button = e.target.closest('.action-btn');
                const action = button.getAttribute('data-action');
                const tokenId = button.getAttribute('data-token-id');
                
                switch (action) {
                    case 'edit':
                        this.editToken(tokenId);
                        break;
                    case 'toggle':
                        this.toggleToken(tokenId);
                        break;
                    case 'delete':
                        this.deleteToken(tokenId);
                        break;
                }
            }
        });
    }

    // 检查认证状态
    checkAuth() {
        if (this.token) {
            this.showMainContent();
            this.loadData();
        } else {
            this.showLoginModal();
        }
    }

    // 显示登录模态框
    showLoginModal() {
        document.getElementById('loginModal').classList.remove('hidden');
        document.getElementById('mainContent').classList.add('hidden');
    }

    // 显示主内容
    showMainContent() {
        document.getElementById('loginModal').classList.add('hidden');
        document.getElementById('mainContent').classList.remove('hidden');
        
        // 更新用户信息
        const userInfo = JSON.parse(localStorage.getItem('adminUser') || '{}');
        document.getElementById('userInfo').textContent = `欢迎, ${userInfo.username || 'Admin'}`;
    }

    // 处理登录
    async handleLogin(e) {
        e.preventDefault();
        
        const formData = new FormData(e.target);
        const credentials = {
            username: formData.get('username'),
            password: formData.get('password')
        };

        try {
            this.showLoading();
            
            const response = await fetch(`${this.baseURL}/auth/login`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(credentials)
            });

            const result = await response.json();

            if (result.success) {
                this.token = result.data.token;
                localStorage.setItem('adminToken', this.token);
                localStorage.setItem('adminUser', JSON.stringify(result.data.user));
                
                this.showMessage('登录成功', 'success');
                this.showMainContent();
                this.loadData();
            } else {
                this.showMessage(result.message || '登录失败', 'error');
            }
        } catch (error) {
            console.error('Login error:', error);
            this.showMessage('登录失败，请检查网络连接', 'error');
        } finally {
            this.hideLoading();
        }
    }

    // 处理登出
    handleLogout() {
        localStorage.removeItem('adminToken');
        localStorage.removeItem('adminUser');
        this.token = null;
        this.showLoginModal();
        this.showMessage('已登出', 'info');
    }

    // 加载数据
    async loadData() {
        await Promise.all([
            this.loadStats(),
            this.loadTokens()
        ]);
    }

    // 加载统计数据
    async loadStats() {
        try {
            const response = await fetch(`${this.baseURL}/tokens/stats/overview`, {
                headers: this.getAuthHeaders()
            });

            if (response.ok) {
                const result = await response.json();
                const stats = result.data;
                
                document.getElementById('totalTokens').textContent = stats.total_tokens;
                document.getElementById('activeTokens').textContent = stats.active_tokens;
                document.getElementById('nativeTokens').textContent = stats.native_tokens;
                document.getElementById('erc20Tokens').textContent = stats.erc20_tokens;
            }
        } catch (error) {
            console.error('Failed to load stats:', error);
        }
    }

    // 加载代币列表
    async loadTokens() {
        try {
            this.showLoading();
            
            // 检查认证状态
            if (!this.token) {
                this.showMessage('请先登录', 'error');
                this.showLoginModal();
                return;
            }
            
            const params = new URLSearchParams({
                page: this.currentPage,
                limit: this.pageSize
            });

            if (this.filters.status !== 'all') {
                params.append('active', this.filters.status === 'active');
            }

            const response = await fetch(`${this.baseURL}/tokens?${params}`, {
                method: 'GET',
                headers: this.getAuthHeaders(),
                // 添加超时和重试机制
                signal: AbortSignal.timeout(10000) // 10秒超时
            });

            if (response.ok) {
                const result = await response.json();
                this.renderTokenTable(result.data.tokens);
                this.renderPagination(result.data.pagination);
            } else if (response.status === 401) {
                // Token过期，需要重新登录
                this.showMessage('登录已过期，请重新登录', 'error');
                this.handleLogout();
            } else {
                this.showMessage(`加载代币列表失败 (${response.status})`, 'error');
            }
        } catch (error) {
            console.error('Failed to load tokens:', error);
            
            if (error.name === 'AbortError') {
                this.showMessage('请求超时，请检查网络连接', 'error');
            } else if (error.message.includes('Failed to fetch')) {
                this.showMessage('无法连接到服务器，请检查后端服务是否正常运行', 'error');
            } else {
                this.showMessage('加载代币列表失败', 'error');
            }
        } finally {
            this.hideLoading();
        }
    }

    // 渲染代币表格
    renderTokenTable(tokens) {
        const tbody = document.getElementById('tokenTableBody');
        
        if (tokens.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="7" class="px-6 py-4 text-center text-gray-500">
                        暂无数据
                    </td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = tokens.map(token => this.renderTokenRow(token)).join('');
    }

    // 渲染代币行
    renderTokenRow(token) {
        const filteredByType = this.filters.type === 'all' || 
            (this.filters.type === 'native' && token.is_native) ||
            (this.filters.type === 'erc20' && !token.is_native);

        if (!filteredByType) return '';

        return `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap">
                    <div class="flex items-center">
                        ${this.renderTokenIcon(token)}
                        <div>
                            <div class="text-sm font-medium text-gray-900">${token.name}</div>
                            <div class="text-sm text-gray-500">${token.symbol}</div>
                        </div>
                    </div>
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                        token.is_native 
                            ? 'bg-purple-100 text-purple-800' 
                            : 'bg-blue-100 text-blue-800'
                    }">
                        ${token.is_native ? '原生代币' : 'ERC20'}
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-mono">
                    ${this.shortenAddress(token.contract_address)}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    ${token.decimals}
                </td>
                <td class="px-6 py-4 whitespace-nowrap">
                    <span class="inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                        token.is_active 
                            ? 'bg-green-100 text-green-800' 
                            : 'bg-red-100 text-red-800'
                    }">
                        ${token.is_active ? '已启用' : '已禁用'}
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    ${token.display_order}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium space-x-2">
                    <button data-action="edit" data-token-id="${token.id}" 
                            class="text-blue-600 hover:text-blue-900 action-btn">
                        <i class="fas fa-edit"></i> 编辑
                    </button>
                    <button data-action="toggle" data-token-id="${token.id}" 
                            class="text-${token.is_active ? 'red' : 'green'}-600 hover:text-${token.is_active ? 'red' : 'green'}-900 action-btn">
                        <i class="fas fa-${token.is_active ? 'ban' : 'check'}"></i> 
                        ${token.is_active ? '禁用' : '启用'}
                    </button>
                    <button data-action="delete" data-token-id="${token.id}" 
                            class="text-red-600 hover:text-red-900 action-btn">
                        <i class="fas fa-trash"></i> 删除
                    </button>
                </td>
            </tr>
        `;
    }

    // 其他方法继续...
    // 获取认证头
    getAuthHeaders() {
        return {
            'Authorization': `Bearer ${this.token}`,
            'Content-Type': 'application/json'
        };
    }

    // 缩短地址显示
    shortenAddress(address) {
        if (!address) return '';
        if (address === '0x0000000000000000000000000000000000000000') return 'ETH';
        return `${address.slice(0, 6)}...${address.slice(-4)}`;
    }

    // 显示加载指示器
    showLoading() {
        document.getElementById('loadingIndicator').classList.remove('hidden');
    }

    // 隐藏加载指示器
    hideLoading() {
        document.getElementById('loadingIndicator').classList.add('hidden');
    }

    // 显示消息
    showMessage(message, type = 'info') {
        const container = document.getElementById('messageContainer');
        const messageId = Date.now();
        
        const colors = {
            success: 'bg-green-500',
            error: 'bg-red-500',
            warning: 'bg-yellow-500',
            info: 'bg-blue-500'
        };

        const messageEl = document.createElement('div');
        messageEl.id = `message-${messageId}`;
        messageEl.className = `${colors[type]} text-white px-4 py-2 rounded-md shadow-lg transform transition-all duration-300 translate-x-full`;
        messageEl.innerHTML = `
            <div class="flex items-center justify-between">
                <span>${message}</span>
                <button onclick="this.parentElement.parentElement.remove()" class="ml-2 text-white hover:text-gray-200">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        `;

        container.appendChild(messageEl);

        // 动画显示
        setTimeout(() => {
            messageEl.classList.remove('translate-x-full');
        }, 100);

        // 自动隐藏
        setTimeout(() => {
            if (messageEl.parentNode) {
                messageEl.classList.add('translate-x-full');
                setTimeout(() => {
                    if (messageEl.parentNode) {
                        messageEl.remove();
                    }
                }, 300);
            }
        }, 5000);
    }

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
                headers: this.getAuthHeaders(),
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

    // 渲染代币图标（简单版本 - 直接使用数据库中的icon_url）
    renderTokenIcon(token) {
        const { symbol, icon_url } = token;
        
        if (icon_url) {
            return `
                <img src="${icon_url}" alt="${symbol}" class="h-8 w-8 rounded-full mr-3"
                     onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                <div class="h-8 w-8 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center text-xs font-bold text-white mr-3" style="display:none;">
                    ${symbol.substring(0, 2).toUpperCase()}
                </div>
            `;
        } else {
            return `
                <div class="h-8 w-8 rounded-full bg-gradient-to-br from-blue-400 to-purple-500 flex items-center justify-center text-xs font-bold text-white mr-3">
                    ${symbol.substring(0, 2).toUpperCase()}
                </div>
            `;
        }
    }
}

// 初始化应用
const tokenAdmin = new TokenAdmin();