function model(
    pDeposition = 0.5, // amount of particles dying before reaching
    D50 = 316, // Amount of particles needed for 50% chance of infection
    emissionBreathing = 0.06, // in cm^3
    emissionSpeaking = 0.6, // in cm^3
    speakingRatio = 0.1, // speaking breathing ratio
    respirationRate = 10, // liters per minute
    virusConcentration = 500000000, // per cm^3
    meanAerosolR = 5, // um
    virusLifetime = 1.7, // in 
    roomArea = 60, // in m^2
    height = 3, // in m^2
    ventilationRate = 0.35, // 0.35 almost never 2 burst of ventilation every hour
    maskEfficiency = 0.2, // 0 - 0.95
) {
    return {
        pDeposition: pDeposition,
        D50: D50,
        emissionBreathing: emissionBreathing,
        emissionSpeaking: emissionSpeaking,
        speakingRatio: speakingRatio,
        respirationRate: respirationRate,
        virusConcentration: virusConcentration,
        meanAerosolR: meanAerosolR,
        virusLifetime: virusLifetime,
        roomArea: roomArea,
        height: height,
        ventilationRate: ventilationRate,
        maskEfficiency: maskEfficiency
    }
}

var autobus = model();


function singleRNA(params) {
    return 1 - Math.pow(10, Math.log10(0.5) / params.D50);
}


// IMORTANT! TIME IS IN MINUTES and the rest is perHour

function RNAinAerosol(params) {
    return params.virusConcentration * Math.PI / 6 * Math.pow(params.meanAerosolR / 10000, 3);
}

function aerosolEmission(params) {
    let particles = params.emissionBreathing*(1-params.speakingRatio) + params.emissionSpeaking*params.speakingRatio;
    return particles * 1000 * params.respirationRate * 60;
}

function aerosolConcentration(params) { // in liters
    return aerosolEmission(params) / (params.roomArea * params.height * 1000);
}

function RNAinLiter(params) {
    return aerosolConcentration(params) * RNAinAerosol(params);
}


function RNAdose(params) {
    return params.respirationRate * 60 * RNAinLiter(params) * params.pDeposition; 
}

function dosis(params, time) {
    return RNAdose(params) / (params.ventilationRate + 1 / params.virusLifetime) * (1 - params.maskEfficiency) * (time/60);
}

function pPerson(params, hours) {
    return (1 - Math.pow(1 - singleRNA(params), dosis(params, hours)))
}

dosis(autobus, 6*60);