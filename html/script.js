let minigameActive = false;
let arrow = null;
let progressContainer = null;
let containerWidth = 0;
let position = 0;
let direction = 1;
let speed = 1.5;
let arrowLeftPos = 0;
let animationFrame = null;
let locks = [];
let lockPositions = [];
let totalAttempts = 0;
let successfulAttempts = 0;
let lockItems = [];
let collectedItems = [];
let greenZones = [];

let inventoryImageConfig = {
    useInventoryPath: false,
    type: "qb",
    path: "qb-inventory/html/images/"
};

function getItemImagePath(itemName) {
    if (inventoryImageConfig.useInventoryPath) {
        return `nui://${inventoryImageConfig.path}${itemName}.png`;
    } else {
        return 'imgs/' + itemName + '.png';
    }
}

const MIN_ZONE_WIDTH = 5;
const MAX_ZONE_WIDTH = 12;
const TOTAL_LOCKS = 5;

function resetMinigameState() {
    if (animationFrame) {
        cancelAnimationFrame(animationFrame);
        animationFrame = null;
    }
    
    minigameActive = false;
    position = 0;
    direction = 1;
    totalAttempts = 0;
    successfulAttempts = 0;
    collectedItems = [];
    lockItems = [];
    greenZones = [];
    lockPositions = [];
    arrow = null;
    
    const locksContainer = document.querySelector('.locks-container');
    if (locksContainer) locksContainer.innerHTML = '';
    
    const zoneContainer = document.querySelector('.zone-container');
    if (zoneContainer) zoneContainer.innerHTML = '';
    
    const instruction = document.querySelector('.instruction');
    if (instruction) instruction.style.display = '';
    
    const keysDiv = document.querySelector('.controls');
    if (keysDiv) keysDiv.style.display = '';
    
    const progressWrapper = document.querySelector('.progress-wrapper');
    if (progressWrapper) progressWrapper.style.display = '';
    
    document.removeEventListener('keydown', handleKeyDown);
    
    fetch(`https://${GetParentResourceName()}/confirmReset`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            status: 'reset_complete'
        })
    });
}

function initMinigame(items, options) {
    resetMinigameState();
    
    if (options && options.inventoryConfig) {
        inventoryImageConfig = options.inventoryConfig;
    }
    
    minigameActive = true;
    position = 0;
    direction = 1;
    totalAttempts = 0;
    successfulAttempts = 0;
    collectedItems = [];
    lockItems = items || [];
    greenZones = [];
    lockPositions = [];
    
    const locksContainer = document.querySelector('.locks-container');
    locksContainer.innerHTML = '';
    
    const zoneContainer = document.querySelector('.zone-container');
    zoneContainer.innerHTML = '';
    
    if (!items || items.length === 0) {
        document.querySelector('.instruction').style.display = 'none';
        
        const noItemsMsg = document.createElement('div');
        noItemsMsg.className = 'no-items';
        noItemsMsg.textContent = 'The pockets are empty...';
        locksContainer.appendChild(noItemsMsg);
        
        const keysDiv = document.querySelector('.controls');
        const progressWrapper = document.querySelector('.progress-wrapper');
        
        keysDiv.style.display = 'none';
        progressWrapper.style.display = 'none';
        
        setTimeout(() => {
            document.body.style.display = 'none';
            
            resetMinigameState();
            
            fetch(`https://${GetParentResourceName()}/closeMinigame`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    emptyPockets: true
                })
            });
        }, 2000);
        
        return;
    }
    
    const itemCount = Math.min(items.length, TOTAL_LOCKS);
    
    const lockElements = [];
    const lockCount = Math.max(itemCount, TOTAL_LOCKS);
    
    for (let i = 0; i < lockCount; i++) {
        const lockDiv = document.createElement('div');
        
        if (i < itemCount) {
            lockDiv.className = 'lock';
            lockDiv.dataset.index = i;
            lockDiv.dataset.name = items[i].name;
            
            const item = items[i];
            
            if (item.name === 'cash') {
                lockDiv.innerHTML = `
                    <img src="${getItemImagePath(item.name)}" 
                         onerror="this.onerror=null; this.src='imgs/default.png';" 
                         alt="${item.label}">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12,17A2,2 0 0,0 14,15C14,13.89 13.1,13 12,13A2,2 0 0,0 10,15A2,2 0 0,0 12,17M18,8A2,2 0 0,1 20,10V20A2,2 0 0,1 18,22H6A2,2 0 0,1 4,20V10C4,8.89 4.9,8 6,8H7V6A5,5 0 0,1 12,1A5,5 0 0,1 17,6V8H18M12,3A3,3 0 0,0 9,6V8H15V6A3,3 0 0,0 12,3Z"/></svg>
                    <span class="value">$${item.amount}</span>
                `;
            } else {
                lockDiv.innerHTML = `
                    <img src="${getItemImagePath(item.name)}" 
                         onerror="this.onerror=null; this.src='imgs/default.png';" 
                         alt="${item.label}">
                    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12,17A2,2 0 0,0 14,15C14,13.89 13.1,13 12,13A2,2 0 0,0 10,15A2,2 0 0,0 12,17M18,8A2,2 0 0,1 20,10V20A2,2 0 0,1 18,22H6A2,2 0 0,1 4,20V10C4,8.89 4.9,8 6,8H7V6A5,5 0 0,1 12,1A5,5 0 0,1 17,6V8H18M12,3A3,3 0 0,0 9,6V8H15V6A3,3 0 0,0 12,3Z"/></svg>
                `;
            }
            
            lockDiv.addEventListener('click', function() {
                if (this.classList.contains('unlocked') && !this.classList.contains('collected')) {
                    this.classList.add('collected');
                    
                    const collectedItemIndex = parseInt(this.dataset.index);
                    collectedItems.push(collectedItemIndex);
                    
                    this.style.transform = 'scale(0.85)';
                    setTimeout(() => {
                        this.style.transform = 'scale(0.9)';
                    }, 100);
                    
                    endMinigame(true);
                }
            });
            
            lockElements.push(lockDiv);
        } else {
            lockDiv.className = 'lock empty';
            lockDiv.innerHTML = `
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12,17A2,2 0 0,0 14,15C14,13.89 13.1,13 12,13A2,2 0 0,0 10,15A2,2 0 0,0 12,17M18,8A2,2 0 0,1 20,10V20A2,2 0 0,1 18,22H6A2,2 0 0,1 4,20V10C4,8.89 4.9,8 6,8H7V6A5,5 0 0,1 12,1A5,5 0 0,1 17,6V8H18M12,3A3,3 0 0,0 9,6V8H15V6A3,3 0 0,0 12,3Z"/></svg>
            `;
            
            lockElements.push(lockDiv);
        }
        
        locksContainer.appendChild(lockDiv);
    }
    
    setTimeout(() => {
        locks = document.querySelectorAll('.lock');
        
        const redBackground = document.createElement('div');
        redBackground.className = 'zone red-zone';
        redBackground.style.width = '100%';
        zoneContainer.appendChild(redBackground);
        
        const progressRect = document.querySelector('.progress-container').getBoundingClientRect();
        const progressWidth = progressRect.width;
        const progressLeft = progressRect.left;
        
        for (let i = 0; i < itemCount; i++) {
            const lockRect = locks[i].getBoundingClientRect();
            
            const lockCenter = lockRect.left + (lockRect.width / 2) - progressLeft;
            const positionPercent = (lockCenter / progressWidth) * 100;
            
            lockPositions.push(positionPercent);
            
            const itemChance = items[i].chance !== undefined ? items[i].chance : 50;
            
            const chanceRatio = Math.sqrt(itemChance / 100);
            const zoneWidth = MIN_ZONE_WIDTH + ((MAX_ZONE_WIDTH - MIN_ZONE_WIDTH) * chanceRatio);
            
            const halfZoneWidth = zoneWidth / 2;
            
            const greenZone = document.createElement('div');
            greenZone.className = 'zone green-zone';
            greenZone.style.position = 'absolute';
            greenZone.style.left = `${positionPercent - halfZoneWidth}%`;
            greenZone.style.width = `${zoneWidth}%`;
            zoneContainer.appendChild(greenZone);
            
            greenZones.push({
                start: positionPercent - halfZoneWidth,
                end: positionPercent + halfZoneWidth,
                lockIndex: i
            });
        }
        
        arrow = document.querySelector('.arrow');
        progressContainer = document.querySelector('.progress-container');
        containerWidth = progressContainer.offsetWidth;
        
        document.addEventListener('keydown', handleKeyDown);
        
        updateArrowPosition();
    }, 0);
    
    document.querySelector('.continue-btn').addEventListener('click', function() {
        endMinigame(successfulAttempts > 0);
    });
}

function updateArrowPosition() {
    if (!minigameActive) return;
    
    position += speed * direction;
    
    if (position >= 100) {
        direction = -1;
    } else if (position <= 0) {
        direction = 1;
    }
    
    arrowLeftPos = (position / 100) * containerWidth;
    arrow.style.left = `${position}%`;
    animationFrame = requestAnimationFrame(updateArrowPosition);
}

function handleKeyDown(e) {
    if (!minigameActive || e.code !== 'Space') return;
    
    e.preventDefault();
    
    let inGreenZone = false;
    let targetLockIndex = -1;
    
    for (const zone of greenZones) {
        if (position >= zone.start && position <= zone.end) {
            inGreenZone = true;
            targetLockIndex = zone.lockIndex;
            break;
        }
    }
    
    totalAttempts++;
    
    if (inGreenZone && targetLockIndex >= 0 && targetLockIndex < locks.length) {
        successfulAttempts++;
        locks[targetLockIndex].classList.add('unlocked');
        
        stopArrowAnimation();
    } else {
        let closestLockIndex = -1;
        let minDistance = 100;
        
        for (const zone of greenZones) {
            const middle = (zone.start + zone.end) / 2;
            const distance = Math.abs(position - middle);
            
            if (distance < minDistance) {
                minDistance = distance;
                closestLockIndex = zone.lockIndex;
            }
        }
        
        if (closestLockIndex >= 0 && closestLockIndex < locks.length) {
            locks[closestLockIndex].classList.add('failed');
        }
        
        if (Math.random() < 0.4) {
            notifyFailedAttempt();
        }
        
        endMinigame(false);
    }
}

function stopArrowAnimation() {
    if (animationFrame) {
        cancelAnimationFrame(animationFrame);
        animationFrame = null;
    }
}

function checkIfAllCollected() {
    const unlockedItems = document.querySelectorAll('.lock.unlocked:not(.collected)');
    return unlockedItems.length === 0;
}

function notifyFailedAttempt() {
    fetch(`https://${GetParentResourceName()}/npcCallingPolice`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function endMinigame(success) {
    minigameActive = false;
    document.removeEventListener('keydown', handleKeyDown);
    stopArrowAnimation();
    
    fetch(`https://${GetParentResourceName()}/minigameComplete`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            success: success,
            successfulAttempts: successfulAttempts,
            totalAttempts: totalAttempts,
            collectedItems: collectedItems
        })
    });
    
    setTimeout(() => {
        document.body.style.display = 'none';
    }, 200);
}

window.addEventListener('load', ensureTransparency);

function ensureTransparency() {
    document.body.style.backgroundColor = 'transparent';
    const html = document.documentElement;
    html.style.backgroundColor = 'transparent';
}

window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.action === 'startMinigame') {
        document.body.style.display = 'flex';
        
        initMinigame(data.items || [], {
            speed: data.speed || 1.5,
            inventoryConfig: data.inventoryConfig || null
        });
        
        ensureTransparency();
    } else if (data.action === 'stopMinigame') {
        document.body.style.display = 'none';
        resetMinigameState();
    } else if (data.action === 'forceReset') {
        resetMinigameState();
        document.body.style.display = 'none';
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        fetch(`https://${GetParentResourceName()}/closeMinigame`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
});

document.body.style.display = 'none';