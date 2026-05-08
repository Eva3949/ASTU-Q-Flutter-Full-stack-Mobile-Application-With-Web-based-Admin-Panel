</div>
    </main>
    
    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- Custom JavaScript -->
    <script src="assets/js/admin.js"></script>
    
    <!-- Page-specific JavaScript -->
    <?php if (isset($page_script)): ?>
    <script src="assets/js/<?php echo $page_script; ?>"></script>
    <?php endif; ?>
    
    <!-- Toast Notification Container -->
    <div class="toast-container position-fixed bottom-0 end-0 p-3" id="toastContainer"></div>
    
    <!-- Loading Overlay -->
    <div class="loading-overlay d-none" id="loadingOverlay">
        <div class="d-flex justify-content-center align-items-center h-100">
            <div class="spinner-border text-primary" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
        </div>
    </div>
    
    <!-- Confirmation Modal -->
    <div class="modal fade" id="confirmModal" tabindex="-1">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="confirmModalTitle">Confirm Action</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body" id="confirmModalBody">
                    Are you sure you want to perform this action?
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-danger" id="confirmModalButton">Confirm</button>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Global JavaScript functions
        window.showToast = function(message, type = 'info') {
            const toastContainer = document.getElementById('toastContainer');
            const toastId = 'toast-' + Date.now();
            
            const toastHtml = `
                <div id="${toastId}" class="toast align-items-center text-white bg-${type === 'error' ? 'danger' : type === 'success' ? 'success' : 'primary'} border-0" role="alert">
                    <div class="d-flex">
                        <div class="toast-body">
                            ${message}
                        </div>
                        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
                    </div>
                </div>
            `;
            
            toastContainer.insertAdjacentHTML('beforeend', toastHtml);
            
            const toastElement = document.getElementById(toastId);
            const toast = new bootstrap.Toast(toastElement);
            toast.show();
            
            toastElement.addEventListener('hidden.bs.toast', () => {
                toastElement.remove();
            });
        };
        
        window.showLoading = function() {
            document.getElementById('loadingOverlay').classList.remove('d-none');
        };
        
        window.hideLoading = function() {
            document.getElementById('loadingOverlay').classList.add('d-none');
        };
        
        window.confirmAction = function(title, message, callback) {
            document.getElementById('confirmModalTitle').textContent = title;
            document.getElementById('confirmModalBody').textContent = message;
            
            const modal = new bootstrap.Modal(document.getElementById('confirmModal'));
            const confirmButton = document.getElementById('confirmModalButton');
            
            confirmButton.onclick = function() {
                modal.hide();
                callback();
            };
            
            modal.show();
        };
        
        // Auto-refresh notifications
        function loadNotifications() {
            fetch('api/notifications?limit=5')
                .then(response => response.json())
                .then(data => {
                    if (data.success) {
                        const badge = document.getElementById('notificationBadge');
                        const menu = document.getElementById('notificationDropdownMenu');
                        
                        badge.textContent = data.data.filter(n => !n.is_read).length;
                        
                        // Update dropdown menu
                        const existingItems = menu.querySelectorAll('li:not(:first-child):not(:last-child):not(:nth-last-child(2))');
                        existingItems.forEach(item => item.remove());
                        
                        if (data.data.length > 0) {
                            data.data.forEach(notification => {
                                const itemHtml = `
                                    <li>
                                        <a class="dropdown-item ${!notification.is_read ? 'bg-light' : ''}" href="#">
                                            <div class="d-flex">
                                                <div class="flex-grow-1">
                                                    <div class="small fw-bold">${notification.title}</div>
                                                    <div class="small text-muted">${notification.message}</div>
                                                    <div class="small text-muted">${formatTime(notification.created_at)}</div>
                                                </div>
                                            </div>
                                        </a>
                                    </li>
                                `;
                                menu.insertAdjacentHTML('beforeend', itemHtml);
                            });
                        } else {
                            const noNotifications = '<li><span class="dropdown-item text-muted">No notifications</span></li>';
                            menu.insertAdjacentHTML('beforeend', noNotifications);
                        }
                    }
                })
                .catch(error => console.error('Error loading notifications:', error));
        }
        
        function formatTime(dateString) {
            const date = new Date(dateString);
            const now = new Date();
            const diff = Math.floor((now - date) / 1000);
            
            if (diff < 60) return 'Just now';
            if (diff < 3600) return Math.floor(diff / 60) + ' minutes ago';
            if (diff < 86400) return Math.floor(diff / 3600) + ' hours ago';
            return date.toLocaleDateString();
        }
        
        // Load notifications on page load
        document.addEventListener('DOMContentLoaded', function() {
            loadNotifications();
            
            // Refresh notifications every 30 seconds
            setInterval(loadNotifications, 30000);
        });
    </script>
</body>
</html>
