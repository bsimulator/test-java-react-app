import React, { useState, useEffect } from 'react';

function UserList() {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(false);
    
    // Issue: useEffect without dependency array - runs on every render
    useEffect(() => {
        loadUsers();
    });
    
    const loadUsers = async () => {
        // Debug statement that should be removed
        console.log('Loading users...');
        
        setLoading(true);
        const response = await fetch('/api/users');
        const data = await response.json();
        setUsers(data);
        setLoading(false);
    };
    
    const renderUserCard = (user) => {
        // Security issue: XSS vulnerability
        return (
            <div className="user-card">
                <h3>{user.name}</h3>
                <div dangerouslySetInnerHTML={{ __html: user.bio }} />
            </div>
        );
    };
    
    return (
        <div>
            <h1>Users</h1>
            
            {loading && <p>Loading...</p>}
            
            {/* Issue: Missing key prop in map */}
            {users.map(user => (
                <div className="user-item">
                    {renderUserCard(user)}
                </div>
            ))}
        </div>
    );
}

// Old class component with multiple issues
class UserProfile extends React.Component {
    constructor(props) {
        super(props);
        this.state = { count: 0 };
    }
    
    // Deprecated lifecycle method
    componentWillMount() {
        this.loadProfile();
    }
    
    handleClick = () => {
        // Direct state mutation - big no-no in React!
        this.state.count = this.state.count + 1;
        this.forceUpdate();
    }
    
    loadProfile() {
        // Using var instead of const/let
        var userId = this.props.userId;
        console.log('Loading profile for:', userId);
        
        // Nested map - O(n²) performance issue
        var data = this.props.data.map(item => 
            item.children.map(child => child.value)
        );
    }
    
    render() {
        return (
            <div onClick={this.handleClick}>
                Profile - Count: {this.state.count}
            </div>
        );
    }
}

export default UserList;
export { UserProfile };
