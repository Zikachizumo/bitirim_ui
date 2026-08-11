const app =
    document.getElementById('app');

const stepGender =
    document.getElementById('stepGender');

const stepIdentity =
    document.getElementById('stepIdentity');

const stepAppearance =
    document.getElementById('stepAppearance');

const stepReview =
    document.getElementById('stepReview');

const pageTitle =
    document.getElementById('pageTitle');


const continueButton =
    document.getElementById('continueButton');

const firstNameInput =
    document.getElementById('firstName');

const lastNameInput =
    document.getElementById('lastName');

const firstNameError =
    document.getElementById('firstNameError');

const lastNameError =
    document.getElementById('lastNameError');

const identityContinue =
    document.getElementById('identityContinue');

const identityBack =
    document.getElementById('identityBack');


const genderCards =
    Array.from(
        document.querySelectorAll('.gender-card')
    );


/* =========================================================
   APPEARANCE DEFINITIONS
   ========================================================= */

const FACE_FEATURES = [
    ['NOSE WIDTH', 0],
    ['NOSE HEIGHT', 1],
    ['NOSE LENGTH', 2],
    ['NOSE BRIDGE', 3],
    ['NOSE TIP', 4],
    ['NOSE SHIFT', 5],

    ['EYEBROW HEIGHT', 6],
    ['EYEBROW DEPTH', 7],

    ['CHEEKBONE HEIGHT', 8],
    ['CHEEKBONE WIDTH', 9],
    ['CHEEK WIDTH', 10],

    ['EYE OPENING', 11],
    ['LIP THICKNESS', 12],

    ['JAW WIDTH', 13],
    ['JAW HEIGHT', 14],

    ['CHIN LENGTH', 15],
    ['CHIN POSITION', 16],
    ['CHIN WIDTH', 17],
    ['CHIN SHAPE', 18],

    ['NECK WIDTH', 19]
];


const EYE_COLORS = [
    'BLACK',
    'LIGHT BLUE / GREEN',
    'DARK BLUE',
    'BROWN',
    'DARK BROWN',
    'LIGHT BROWN',
    'BLUE',
    'LIGHT BLUE'
];


function defaultAppearance() {

    const face = {};

    for (let i = 0; i < 20; i++) {
        face[i] = 0;
    }

    return {
        mother: 21,
        father: 0,

        resemblance: 0.5,
        skinMix: 0.5,

        eyeColor: 3,

        ageing: -1,
        complexion: -1,
        moles: -1,

        face
    };

}


let state = {
    open: false,

    step: 1,

    gender: null,

    firstName: '',
    lastName: '',

    focusedCard: 0,

    continueFocused: false,

    appearance:
        defaultAppearance()
};


/* =========================================================
   NUI
   ========================================================= */

function postNui(endpoint, data = {}) {

    return fetch(
        `https://${GetParentResourceName()}/${endpoint}`,
        {
            method: 'POST',

            headers: {
                'Content-Type':
                    'application/json; charset=UTF-8'
            },

            body:
                JSON.stringify(data)
        }
    ).catch(() => {});

}


/* =========================================================
   NAME VALIDATION
   ========================================================= */

function cleanName(value) {

    return String(value || '')
        .replace(/\s+/g, ' ')
        .trim();

}


function nameIsValid(value) {

    const name =
        cleanName(value);

    if (
        name.length < 2 ||
        name.length > 20
    ) {
        return false;
    }

    return /^[A-Za-zÀ-ÖØ-öø-ÿ]+$/.test(
        name
    );

}


function getNameError(value) {

    const name =
        cleanName(value);

    if (!name.length) {
        return '';
    }

    if (name.length < 2) {
        return 'Minimum 2 characters.';
    }

    if (name.length > 20) {
        return 'Maximum 20 characters.';
    }

    if (
        !/^[A-Za-zÀ-ÖØ-öø-ÿ]+$/.test(name)
    ) {
        return 'Letters only.';
    }

    return '';

}


/* =========================================================
   CREATOR OPEN/CLOSE
   ========================================================= */

function openCreator(initialState = {}) {

    state.open = true;

    state.step =
        Number(initialState.step || 1);

    state.gender =
        initialState.gender || null;

    state.firstName =
        initialState.firstName || '';

    state.lastName =
        initialState.lastName || '';

    state.appearance =
        normalizeAppearance(
            initialState.appearance
        );

    state.focusedCard = 0;
    state.continueFocused = false;

    firstNameInput.value =
        state.firstName;

    lastNameInput.value =
        state.lastName;

    app.classList.remove('hidden');

    renderStep();

}


function closeCreator() {

    state.open = false;

    app.classList.remove(
        'appearance-live'
    );

    app.classList.add('hidden');

}


/* =========================================================
   APPEARANCE NORMALIZATION
   ========================================================= */

function normalizeAppearance(data) {

    const base =
        defaultAppearance();

    if (!data) {
        return base;
    }

    base.mother =
        Number(data.mother ?? base.mother);

    base.father =
        Number(data.father ?? base.father);

    base.resemblance =
        Number(
            data.resemblance ??
            base.resemblance
        );

    base.skinMix =
        Number(
            data.skinMix ??
            base.skinMix
        );

    base.eyeColor =
        Number(
            data.eyeColor ??
            base.eyeColor
        );

    base.ageing =
        Number(
            data.ageing ??
            base.ageing
        );

    base.complexion =
        Number(
            data.complexion ??
            base.complexion
        );

    base.moles =
        Number(
            data.moles ??
            base.moles
        );

    if (data.face) {

        for (let i = 0; i < 20; i++) {

            base.face[i] =
                Number(
                    data.face[i] ??
                    data.face[String(i)] ??
                    0
                );

        }

    }

    return base;

}


/* =========================================================
   GENDER
   ========================================================= */

function syncGenderCards() {

    genderCards.forEach(
        (card, index) => {

            const gender =
                card.dataset.gender;

            card.classList.toggle(
                'selected',
                gender === state.gender
            );

            card.classList.toggle(
                'focused',
                !state.continueFocused &&
                index === state.focusedCard
            );

        }
    );

    continueButton.disabled =
        !state.gender;

    continueButton.classList.toggle(
        'focused',
        state.continueFocused &&
        !!state.gender
    );

}


function selectGender(gender) {

    if (
        gender !== 'female' &&
        gender !== 'male'
    ) {
        return;
    }

    state.gender = gender;

    const index =
        genderCards.findIndex(
            card =>
                card.dataset.gender === gender
        );

    if (index >= 0) {
        state.focusedCard = index;
    }

    state.continueFocused = true;

    syncGenderCards();

    postNui(
        'selectGender',
        { gender }
    );

}


function continueGender() {

    if (!state.gender) {
        return;
    }

    postNui('continueGender');

}


/* =========================================================
   IDENTITY
   ========================================================= */

function syncIdentity() {

    state.firstName =
        cleanName(
            firstNameInput.value
        );

    state.lastName =
        cleanName(
            lastNameInput.value
        );

    const firstValid =
        nameIsValid(
            state.firstName
        );

    const lastValid =
        nameIsValid(
            state.lastName
        );

    const firstShell =
        firstNameInput.closest(
            '.input-shell'
        );

    const lastShell =
        lastNameInput.closest(
            '.input-shell'
        );

    firstShell.classList.toggle(
        'valid',
        firstValid
    );

    firstShell.classList.toggle(
        'invalid',
        !!firstNameInput.value &&
        !firstValid
    );

    lastShell.classList.toggle(
        'valid',
        lastValid
    );

    lastShell.classList.toggle(
        'invalid',
        !!lastNameInput.value &&
        !lastValid
    );

    firstNameError.textContent =
        getNameError(
            firstNameInput.value
        );

    lastNameError.textContent =
        getNameError(
            lastNameInput.value
        );

    identityContinue.disabled =
        !firstValid ||
        !lastValid;

}


function saveIdentity() {

    syncIdentity();

    if (identityContinue.disabled) {
        return;
    }

    postNui(
        'saveIdentity',
        {
            firstName:
                state.firstName,

            lastName:
                state.lastName
        }
    );

}


/* =========================================================
   APPEARANCE DOM
   ========================================================= */

const appearanceTabs =
    Array.from(
        document.querySelectorAll(
            '.appearance-tab'
        )
    );

const appearancePages = {
    heritage:
        document.getElementById(
            'appearanceHeritage'
        ),

    face:
        document.getElementById(
            'appearanceFace'
        ),

    details:
        document.getElementById(
            'appearanceDetails'
        )
};


const motherValue =
    document.getElementById(
        'motherValue'
    );

const fatherValue =
    document.getElementById(
        'fatherValue'
    );

const resemblance =
    document.getElementById(
        'resemblance'
    );

const resemblanceValue =
    document.getElementById(
        'resemblanceValue'
    );

const skinMix =
    document.getElementById(
        'skinMix'
    );

const skinMixValue =
    document.getElementById(
        'skinMixValue'
    );

const eyeValue =
    document.getElementById(
        'eyeValue'
    );

const ageing =
    document.getElementById(
        'ageing'
    );

const complexion =
    document.getElementById(
        'complexion'
    );

const moles =
    document.getElementById(
        'moles'
    );


/* =========================================================
   FACE FEATURE UI GENERATION
   ========================================================= */

const faceFeatureList =
    document.getElementById(
        'faceFeatureList'
    );


FACE_FEATURES.forEach(
    ([name, index]) => {

        const row =
            document.createElement(
                'div'
            );

        row.className =
            'face-feature-row';

        row.innerHTML = `
            <span class="face-feature-name">
                ${name}
            </span>

            <input
                class="face-feature-slider"
                data-index="${index}"
                type="range"
                min="-100"
                max="100"
                step="1"
                value="0"
            >

            <span
                class="face-feature-number"
                data-value-for="${index}"
            >
                0
            </span>
        `;

        faceFeatureList.appendChild(
            row
        );

    }
);


/* =========================================================
   APPEARANCE TAB
   ========================================================= */

function switchAppearanceTab(name) {

    appearanceTabs.forEach(
        tab => {

            tab.classList.toggle(
                'active',
                tab.dataset.tab === name
            );

        }
    );

    Object.entries(
        appearancePages
    ).forEach(
        ([key, page]) => {

            page.classList.toggle(
                'active',
                key === name
            );

        }
    );

    if (
        name === 'face' ||
        name === 'details'
    ) {
        postNui(
            'appearanceCamera',
            { mode: 'face' }
        );
    }

}


appearanceTabs.forEach(
    tab => {

        tab.addEventListener(
            'click',
            () => {

                switchAppearanceTab(
                    tab.dataset.tab
                );

            }
        );

    }
);


/* =========================================================
   HERITAGE UI
   ========================================================= */

function motherLabel() {

    return `MOTHER ${String(
        state.appearance.mother - 20
    ).padStart(2, '0')}`;

}


function fatherLabel() {

    return `FATHER ${String(
        state.appearance.father + 1
    ).padStart(2, '0')}`;

}


function sendHeritage() {

    postNui(
        'appearanceUpdate',
        {
            kind: 'heritage',

            mother:
                state.appearance.mother,

            father:
                state.appearance.father,

            resemblance:
                state.appearance.resemblance,

            skinMix:
                state.appearance.skinMix
        }
    );

}


function syncAppearanceUI() {

    motherValue.textContent =
        motherLabel();

    fatherValue.textContent =
        fatherLabel();

    resemblance.value =
        Math.round(
            state.appearance.resemblance *
            100
        );

    resemblanceValue.textContent =
        `${resemblance.value}%`;

    skinMix.value =
        Math.round(
            state.appearance.skinMix *
            100
        );

    skinMixValue.textContent =
        `${skinMix.value}%`;

    eyeValue.textContent =
        EYE_COLORS[
            state.appearance.eyeColor
        ] ||
        'BROWN';

    ageing.value =
        state.appearance.ageing;

    complexion.value =
        state.appearance.complexion;

    moles.value =
        state.appearance.moles;

    document.getElementById(
        'ageingText'
    ).textContent =
        detailText(
            state.appearance.ageing
        );

    document.getElementById(
        'complexionText'
    ).textContent =
        detailText(
            state.appearance.complexion
        );

    document.getElementById(
        'molesText'
    ).textContent =
        detailText(
            state.appearance.moles
        );

    document
        .querySelectorAll(
            '.face-feature-slider'
        )
        .forEach(
            slider => {

                const index =
                    Number(
                        slider.dataset.index
                    );

                const value =
                    state.appearance.face[index] ||
                    0;

                slider.value =
                    Math.round(
                        value * 100
                    );

                const numberLabel =
                    document.querySelector(
                        `[data-value-for="${index}"]`
                    );

                if (numberLabel) {

                    numberLabel.textContent =
                        slider.value;

                }

            }
        );

}


function detailText(value) {

    const number =
        Number(value);

    if (number < 0) {
        return 'NONE';
    }

    return `STYLE ${number + 1}`;

}


/* =========================================================
   HERITAGE EVENTS
   ========================================================= */

document.getElementById(
    'motherPrev'
).addEventListener(
    'click',
    () => {

        state.appearance.mother--;

        if (
            state.appearance.mother < 21
        ) {
            state.appearance.mother = 41;
        }

        syncAppearanceUI();

        sendHeritage();

    }
);


document.getElementById(
    'motherNext'
).addEventListener(
    'click',
    () => {

        state.appearance.mother++;

        if (
            state.appearance.mother > 41
        ) {
            state.appearance.mother = 21;
        }

        syncAppearanceUI();

        sendHeritage();

    }
);


document.getElementById(
    'fatherPrev'
).addEventListener(
    'click',
    () => {

        state.appearance.father--;

        if (
            state.appearance.father < 0
        ) {
            state.appearance.father = 20;
        }

        syncAppearanceUI();

        sendHeritage();

    }
);


document.getElementById(
    'fatherNext'
).addEventListener(
    'click',
    () => {

        state.appearance.father++;

        if (
            state.appearance.father > 20
        ) {
            state.appearance.father = 0;
        }

        syncAppearanceUI();

        sendHeritage();

    }
);


resemblance.addEventListener(
    'input',
    () => {

        state.appearance.resemblance =
            Number(
                resemblance.value
            ) /
            100;

        resemblanceValue.textContent =
            `${resemblance.value}%`;

        sendHeritage();

    }
);


skinMix.addEventListener(
    'input',
    () => {

        state.appearance.skinMix =
            Number(
                skinMix.value
            ) /
            100;

        skinMixValue.textContent =
            `${skinMix.value}%`;

        sendHeritage();

    }
);


/* =========================================================
   FACE EVENTS
   ========================================================= */

document
    .querySelectorAll(
        '.face-feature-slider'
    )
    .forEach(
        slider => {

            slider.addEventListener(
                'input',
                () => {

                    const index =
                        Number(
                            slider.dataset.index
                        );

                    const value =
                        Number(
                            slider.value
                        ) /
                        100;

                    state.appearance.face[index] =
                        value;

                    const numberLabel =
                        document.querySelector(
                            `[data-value-for="${index}"]`
                        );

                    if (numberLabel) {

                        numberLabel.textContent =
                            slider.value;

                    }

                    postNui(
                        'appearanceUpdate',
                        {
                            kind:
                                'face',

                            index,

                            value
                        }
                    );

                }
            );

        }
    );


/* =========================================================
   EYES
   ========================================================= */

function changeEye(direction) {

    let value =
        state.appearance.eyeColor +
        direction;

    if (value < 0) {
        value =
            EYE_COLORS.length - 1;
    }

    if (
        value >=
        EYE_COLORS.length
    ) {
        value = 0;
    }

    state.appearance.eyeColor =
        value;

    syncAppearanceUI();

    postNui(
        'appearanceUpdate',
        {
            kind:
                'eyeColor',

            value
        }
    );

}


document.getElementById(
    'eyePrev'
).addEventListener(
    'click',
    () => changeEye(-1)
);


document.getElementById(
    'eyeNext'
).addEventListener(
    'click',
    () => changeEye(1)
);


/* =========================================================
   DETAILS
   ========================================================= */

[
    ['ageing', ageing],
    ['complexion', complexion],
    ['moles', moles]
].forEach(
    ([name, element]) => {

        element.addEventListener(
            'input',
            () => {

                const value =
                    Number(
                        element.value
                    );

                state.appearance[name] =
                    value;

                document.getElementById(
                    `${name}Text`
                ).textContent =
                    detailText(value);

                postNui(
                    'appearanceUpdate',
                    {
                        kind:
                            'detail',

                        name,

                        value
                    }
                );

            }
        );

    }
);


/* =========================================================
   RANDOMIZE / RESET
   ========================================================= */

document.getElementById(
    'randomizeAppearance'
).addEventListener(
    'click',
    () => {

        postNui(
            'appearanceRandomize'
        );

    }
);


document.getElementById(
    'resetAppearance'
).addEventListener(
    'click',
    () => {

        postNui(
            'appearanceReset'
        );

    }
);


/* =========================================================
   ROTATION
   ========================================================= */

document.getElementById(
    'rotateLeft'
).addEventListener(
    'click',
    () => {

        postNui(
            'appearanceRotate',
            {
                direction: -1
            }
        );

    }
);


document.getElementById(
    'rotateRight'
).addEventListener(
    'click',
    () => {

        postNui(
            'appearanceRotate',
            {
                direction: 1
            }
        );

    }
);


/* =========================================================
   CAMERA
   ========================================================= */

const cameraFace =
    document.getElementById(
        'cameraFace'
    );

const cameraBody =
    document.getElementById(
        'cameraBody'
    );


function selectCamera(mode) {

    cameraFace.classList.toggle(
        'active',
        mode === 'face'
    );

    cameraBody.classList.toggle(
        'active',
        mode === 'body'
    );

    postNui(
        'appearanceCamera',
        { mode }
    );

}


cameraFace.addEventListener(
    'click',
    () => selectCamera('face')
);


cameraBody.addEventListener(
    'click',
    () => selectCamera('body')
);


/* =========================================================
   APPEARANCE ACTIONS
   ========================================================= */

document.getElementById(
    'appearanceBack'
).addEventListener(
    'click',
    () => {

        postNui('back');

    }
);


document.getElementById(
    'appearanceContinue'
).addEventListener(
    'click',
    () => {

        postNui(
            'appearanceContinue'
        );

    }
);


/* =========================================================
   GENDER MOUSE
   ========================================================= */

genderCards.forEach(
    (card, index) => {

        card.addEventListener(
            'mouseenter',
            () => {

                if (
                    !state.open ||
                    state.step !== 1
                ) {
                    return;
                }

                state.focusedCard =
                    index;

                state.continueFocused =
                    false;

                syncGenderCards();

            }
        );


        card.addEventListener(
            'click',
            () => {

                if (
                    !state.open ||
                    state.step !== 1
                ) {
                    return;
                }

                selectGender(
                    card.dataset.gender
                );

            }
        );

    }
);


continueButton.addEventListener(
    'mouseenter',
    () => {

        if (
            state.step !== 1 ||
            !state.gender
        ) {
            return;
        }

        state.continueFocused =
            true;

        syncGenderCards();

    }
);


continueButton.addEventListener(
    'click',
    continueGender
);


/* =========================================================
   IDENTITY EVENTS
   ========================================================= */

firstNameInput.addEventListener(
    'input',
    syncIdentity
);


lastNameInput.addEventListener(
    'input',
    syncIdentity
);


identityContinue.addEventListener(
    'click',
    saveIdentity
);


identityBack.addEventListener(
    'click',
    () => postNui('back')
);


/* =========================================================
   RENDER STEPS
   ========================================================= */

function hideAllSteps() {

    stepGender.classList.add(
        'hidden'
    );

    stepIdentity.classList.add(
        'hidden'
    );

    stepAppearance.classList.add(
        'hidden'
    );

    stepReview.classList.add(
        'hidden'
    );

}


function renderStep() {

    hideAllSteps();

    app.classList.toggle(
        'appearance-live',
        state.step >= 3
    );


    if (state.step === 1) {

        pageTitle.textContent =
            'CREATE CHARACTER';

        stepGender.classList.remove(
            'hidden'
        );

        syncGenderCards();

        return;
    }


    if (state.step === 2) {

        pageTitle.textContent =
            'IDENTITY DETAILS';

        stepIdentity.classList.remove(
            'hidden'
        );

        firstNameInput.value =
            state.firstName || '';

        lastNameInput.value =
            state.lastName || '';

        syncIdentity();

        setTimeout(
            () => {
                firstNameInput.focus();
            },
            100
        );

        return;
    }


    if (state.step === 3) {

        pageTitle.textContent =
            'APPEARANCE';

        stepAppearance.classList.remove(
            'hidden'
        );

        syncAppearanceUI();

        switchAppearanceTab(
            'heritage'
        );

        return;
    }


    pageTitle.textContent =
        'REVIEW';

    stepReview.classList.remove(
        'hidden'
    );

    const genderText =
        state.gender === 'female'
            ? 'FEMALE'
            : 'MALE';

    document.getElementById(
        'reviewSummary'
    ).textContent =
        `${state.firstName} ${state.lastName} • ${genderText}`;

}


/* =========================================================
   KEYBOARD
   ========================================================= */

window.addEventListener(
    'keydown',
    event => {

        if (!state.open) {
            return;
        }


        if (event.key === 'Escape') {

            event.preventDefault();

            postNui('back');

            return;
        }


        if (state.step === 1) {

            if (
                event.key === 'ArrowLeft' ||
                event.key === 'a' ||
                event.key === 'A'
            ) {

                event.preventDefault();

                state.continueFocused =
                    false;

                state.focusedCard--;

                if (
                    state.focusedCard < 0
                ) {
                    state.focusedCard =
                        genderCards.length - 1;
                }

                syncGenderCards();

                return;
            }


            if (
                event.key === 'ArrowRight' ||
                event.key === 'd' ||
                event.key === 'D'
            ) {

                event.preventDefault();

                state.continueFocused =
                    false;

                state.focusedCard =
                    (
                        state.focusedCard + 1
                    ) %
                    genderCards.length;

                syncGenderCards();

                return;
            }


            if (
                event.key === 'ArrowDown' ||
                event.key === 's' ||
                event.key === 'S'
            ) {

                if (state.gender) {

                    event.preventDefault();

                    state.continueFocused =
                        true;

                    syncGenderCards();

                }

                return;
            }


            if (event.key === 'Enter') {

                event.preventDefault();

                if (
                    state.continueFocused &&
                    state.gender
                ) {

                    continueGender();

                    return;
                }

                const card =
                    genderCards[
                        state.focusedCard
                    ];

                if (card) {

                    selectGender(
                        card.dataset.gender
                    );

                }

            }

            return;
        }


        if (
            state.step === 2 &&
            event.key === 'Enter' &&
            !identityContinue.disabled
        ) {

            event.preventDefault();

            saveIdentity();

            return;
        }


        if (state.step === 3) {

            if (
                event.key === 'q' ||
                event.key === 'Q'
            ) {

                postNui(
                    'appearanceRotate',
                    { direction: -1 }
                );

                return;
            }


            if (
                event.key === 'e' ||
                event.key === 'E'
            ) {

                postNui(
                    'appearanceRotate',
                    { direction: 1 }
                );

            }

        }

    }
);


/* =========================================================
   LUA -> NUI
   ========================================================= */

window.addEventListener(
    'message',
    event => {

        const data =
            event.data || {};


        if (
            data.action === 'open'
        ) {

            openCreator(
                data.state || {}
            );

            return;
        }


        if (
            data.action === 'close'
        ) {

            closeCreator();

            return;
        }


        if (
            data.action === 'appearanceState'
        ) {

            state.appearance =
                normalizeAppearance(
                    data.appearance
                );

            syncAppearanceUI();

            return;
        }


        if (
            data.action === 'step'
        ) {

            state.step =
                Number(
                    data.step || 1
                );


            if (data.state) {

                if (
                    data.state.gender !==
                    undefined
                ) {
                    state.gender =
                        data.state.gender;
                }


                if (
                    data.state.firstName !==
                    undefined
                ) {
                    state.firstName =
                        data.state.firstName || '';
                }


                if (
                    data.state.lastName !==
                    undefined
                ) {
                    state.lastName =
                        data.state.lastName || '';
                }


                if (
                    data.state.appearance
                ) {
                    state.appearance =
                        normalizeAppearance(
                            data.state.appearance
                        );
                }

            }

            renderStep();

        }

    }
);


/* =========================================================
   RADIAL CORNER DOTS
   ========================================================= */

const canvas =
    document.getElementById(
        'dotCanvas'
    );

const ctx =
    canvas.getContext('2d');


function noise(x, y, seed = 1) {

    const value =
        Math.sin(
            x * 12.9898 +
            y * 78.233 +
            seed * 37.719
        ) *
        43758.5453;

    return (
        value -
        Math.floor(value)
    );

}


function drawCornerDots(
    originX,
    originY,
    xDirection,
    yDirection
) {

    const width =
        window.innerWidth;

    const height =
        window.innerHeight;

    const spacing =
        Math.max(
            10,
            Math.round(
                width / 170
            )
        );

    const radius =
        Math.min(
            Math.max(
                width * 0.34,
                390
            ),
            690
        );

    const xStart =
        xDirection > 0
            ? originX
            : Math.max(
                0,
                originX - radius
            );

    const xEnd =
        xDirection > 0
            ? Math.min(
                width,
                originX + radius
            )
            : originX;

    const yStart =
        yDirection > 0
            ? originY
            : Math.max(
                0,
                originY - radius
            );

    const yEnd =
        yDirection > 0
            ? Math.min(
                height,
                originY + radius
            )
            : originY;


    for (
        let y = yStart;
        y <= yEnd;
        y += spacing
    ) {

        for (
            let x = xStart;
            x <= xEnd;
            x += spacing
        ) {

            const dx =
                (x - originX) *
                xDirection;

            const dy =
                (y - originY) *
                yDirection;

            if (
                dx < 0 ||
                dy < 0
            ) {
                continue;
            }

            const distance =
                Math.sqrt(
                    dx * dx +
                    dy * dy
                );

            if (
                distance > radius
            ) {
                continue;
            }

            const normalized =
                distance / radius;

            const density =
                Math.pow(
                    1 - normalized,
                    0.78
                );

            const random =
                noise(
                    Math.round(
                        x / spacing
                    ),
                    Math.round(
                        y / spacing
                    ),
                    8
                );

            if (
                random >
                density * 1.12
            ) {
                continue;
            }

            let opacity =
                Math.pow(
                    1 - normalized,
                    1.85
                ) *
                0.35;

            opacity *=
                Math.min(
                    1,
                    distance /
                    (
                        radius *
                        0.13
                    )
                );

            if (
                opacity < 0.012
            ) {
                continue;
            }

            const dotSize =
                0.8 +
                noise(
                    x,
                    y,
                    4
                ) *
                0.75;

            ctx.beginPath();

            ctx.fillStyle =
                `rgba(190,90,255,${opacity})`;

            ctx.arc(
                x,
                y,
                dotSize,
                0,
                Math.PI * 2
            );

            ctx.fill();

        }

    }

}


function drawDots() {

    const dpr =
        window.devicePixelRatio ||
        1;

    canvas.width =
        Math.floor(
            window.innerWidth *
            dpr
        );

    canvas.height =
        Math.floor(
            window.innerHeight *
            dpr
        );

    canvas.style.width =
        `${window.innerWidth}px`;

    canvas.style.height =
        `${window.innerHeight}px`;

    ctx.setTransform(
        dpr,
        0,
        0,
        dpr,
        0,
        0
    );

    ctx.clearRect(
        0,
        0,
        window.innerWidth,
        window.innerHeight
    );

    drawCornerDots(
        -window.innerWidth * 0.035,
        -window.innerHeight * 0.08,
        1,
        1
    );

    drawCornerDots(
        window.innerWidth * 1.035,
        window.innerHeight * 1.08,
        -1,
        -1
    );

}


window.addEventListener(
    'resize',
    drawDots
);


drawDots();
