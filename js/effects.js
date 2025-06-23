document.addEventListener('DOMContentLoaded', () => {
    const effectTriggers = document.querySelectorAll('[data-effect]');

    const effects = {
        works: ['0', '1', 'A', 'B', 'C', '{', '}', ';', '/', '>', '<'],
        apps: ['📱', '💻', '💡', '🚀', '⭐'],
        music: ['🎵', '🎶', '🎼', '♭', '♯', '♩', '♪', '♫'],
        photography: ['☀️', '🌙', '⭐', '🌳', '🌸', '⛰️', '🌊']
    };

    const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;

    if (isTouchDevice) {
        // --- Mobile & Touch Device Logic ---
        effectTriggers.forEach(trigger => {
            trigger.addEventListener('touchstart', (e) => {
                const effectType = e.currentTarget.dataset.effect;
                if (!effects[effectType]) return;

                // On tap, create a burst of 20 particles
                for (let i = 0; i < 20; i++) {
                    createParticle(effects[effectType]);
                }
            }, { passive: true });
        });
    } else {
        // --- Desktop (Mouse) Logic ---
        let intervalId = null;
        effectTriggers.forEach(trigger => {
            trigger.addEventListener('mouseenter', (e) => {
                const effectType = e.currentTarget.dataset.effect;
                if (!effects[effectType]) return;

                // Start creating particles on hover
                intervalId = setInterval(() => {
                    createParticle(effects[effectType]);
                }, 100);
            });

            trigger.addEventListener('mouseleave', () => {
                // Stop creating particles when hover ends
                clearInterval(intervalId);
            });
        });
    }

    function createParticle(characters) {
        const particle = document.createElement('span');
        particle.classList.add('particle');
        document.body.appendChild(particle);

        const character = characters[Math.floor(Math.random() * characters.length)];
        particle.textContent = character;

        // Position and animation
        const startX = Math.random() * window.innerWidth;
        const startY = Math.random() * window.innerHeight;
        
        const endX = startX + (Math.random() * 400 - 200);
        const endY = startY + (Math.random() * 400 - 200);

        const duration = Math.random() * 2000 + 3000; // 3-5 seconds

        particle.style.transform = `translate(${startX}px, ${startY}px)`;

        const animation = particle.animate([
            { transform: `translate(${startX}px, ${startY}px) scale(0.8)`, opacity: 1 },
            { transform: `translate(${endX}px, ${endY}px) scale(1.2)`, opacity: 0 }
        ], {
            duration: duration,
            easing: 'cubic-bezier(0.25, 1, 0.5, 1)',
            fill: 'forwards'
        });

        animation.onfinish = () => {
            particle.remove();
        };
    }
}); 