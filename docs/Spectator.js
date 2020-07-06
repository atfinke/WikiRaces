const CLOUD_KIT_ENV = "production";
const CLOUD_KEY_API_TOKEN = "3bb9e19a5e4594ce75d46f98fca2c453b857d3e0ff0eceaf8be3a598cbf24e49";

const WKRGameState = Object.freeze({
    preMatch: 0,
    voting: 1,
    race: 2,
    results: 3,
    hostResults: 4,
    points: 5,
});

const AssetType = Object.freeze({
    imageContainer: 0,
    resultsInfo: 1,
    config: 2,
});

var activeRaceCode = null;
var activeResultsInfo = null;
var activeImageContainerItems = null;
var activeGameState = WKRGameState.preMatch;

var initalInterfaceLoaded = false;

function start() {
    let raceCode = raceCodeFromURL();
    if (raceCode == null) {
        raceCode = prompt("Enter Race Code");
    }
    startWithRaceCode(raceCode);
}

function raceCodeFromURL() {
    let urlParams = new URLSearchParams(window.location.search);
    if (urlParams != null && urlParams.has("Code")) {
        return urlParams.get("Code");
    } else {
        return null;
    }
}

function startWithRaceCode(raceCode) {
    activeRaceCode = raceCode;
    activeResultsInfo = null;
    activeImageContainerItems = null;
    initalInterfaceLoaded = false;
    fetchDataForRaceCode(raceCode);
}

function fetchDataForRaceCode(raceCode) {
    let url =
        "https://api.apple-cloudkit.com/database/1/iCloud.com.andrewfinke.wikiraces/" +
        CLOUD_KIT_ENV +
        "/public/records/query?ckAPIToken=" +
        CLOUD_KEY_API_TOKEN;

    let xhr = new XMLHttpRequest();
    xhr.responseType = "json";
    xhr.open("POST", url, true);
    xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    xhr.onload = function (e) {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                receivedResponse(xhr.response);
            } else {
                console.error(xhr.statusText);
            }
            setTimeout(function () {
                fetchDataForRaceCode(raceCode);
            }, 5000);
        }
    };

    xhr.onerror = function (e) {
        console.error(xhr.statusText);
    };

    xhr.send(
        JSON.stringify({
            query: {
                recordType: "RaceActive",
                filterBy: [
                    {
                        fieldName: "Code",
                        comparator: "EQUALS",
                        fieldValue: {
                            value: raceCode.toLowerCase(),
                            type: "STRING",
                        },
                    },
                ],
                sortBy: [
                    {
                        systemFieldName: "modifiedTimestamp",
                        ascending: false,
                    },
                ],
            },
        })
    );
}

function receivedResponse(response) {
    if (!response.hasOwnProperty("records")) {
        console.error("Invalid Response: " + response);
        return;
    }

    let records = response["records"];
    if (records.length == 0) {
        console.error("No Records: " + response);
        return;
    }

    let record = records[0];
    if (!record.hasOwnProperty("modified") || !record.hasOwnProperty("fields")) {
        console.error("Invalid Record: " + record);
        return;
    }

    let modifiedObject = record["modified"];
    if (!modifiedObject.hasOwnProperty("timestamp")) {
        console.error("Invalid Modified: " + modifiedObject);
        return;
    }
    let modifiedTimestamp = modifiedObject["timestamp"];

    let fields = record["fields"];
    if (
        !fields.hasOwnProperty("Code") ||
        !fields.hasOwnProperty("Host") ||
        !fields.hasOwnProperty("State") ||
        !fields.hasOwnProperty("Version")
    ) {
        console.error("Invalid Fields: " + fields);
        return;
    }

    let code = fields["Code"]["value"];
    let host = fields["Host"]["value"];
    let version = fields["Version"]["value"];
    activeGameState = fields["State"]["value"];
    if (activeGameState != WKRGameState.race && activeGameState != WKRGameState.results) {
        updateStatusLabel(statusForGameState(activeGameState));
    }
    

    if (fields.hasOwnProperty("Config")) {
        downloadAssetRecord(fields["Config"], AssetType.config);
    } else {
        console.error("No Config Info");
    }

    if (fields.hasOwnProperty("ResultsInfo")) {
        downloadAssetRecord(fields["ResultsInfo"], AssetType.resultsInfo);
    } else {
        console.error("No Results Info");
    }

    if (activeImageContainerItems == null) {
        if (fields.hasOwnProperty("ImageContainer")) {
            downloadAssetRecord(fields["ImageContainer"], AssetType.imageContainer);
        } else {
            console.error("No Results Info");
        }
    } else {
        console.log("Already have images");
    }
}

function downloadAssetRecord(asset, assetType) {
    if (asset.hasOwnProperty("value") && asset["value"].hasOwnProperty("downloadURL")) {
        let downloadURL = asset["value"]["downloadURL"];
        downloadAsset(downloadURL, assetType);
    } else {
        console.error("No asset Info");
    }
}

function downloadAsset(url, assetType) {
    let xhr = new XMLHttpRequest();
    xhr.open("GET", url, true);
    xhr.setRequestHeader("Content-Type", "application/json;charset=UTF-8");
    xhr.responseType = "json";

    xhr.onload = function (e) {
        if (xhr.readyState === 4) {
            if (xhr.status === 200) {
                if (assetType == AssetType.imageContainer) {
                    receivedImageContainer(xhr.response);
                } else if (assetType == AssetType.resultsInfo) {
                    receivedResultsInfo(xhr.response);
                } else if (assetType == AssetType.config) {
                    receivedConfig(xhr.response);
                }
            } else {
                console.error(xhr.statusText);
            }
        }
    };

    xhr.onerror = function (e) {
        console.error(xhr.statusText);
    };

    xhr.send();
}

function receivedResultsInfo(resultsInfo) {
    if (!resultsInfo.hasOwnProperty("playersSortedByPoints")) {
        console.error("Invalid Results Info: " + resultsInfo);
        return;
    }
    let players = resultsInfo["playersSortedByPoints"];
    for (const playerObject of players) {
        let playerID = playerObject["profile"]["playerID"];
        let entries = playerObject["raceHistory"]["entries"];
        let lastEntry = entries[entries.length - 1];
        let title = lastEntry["page"]["title"];
        for (const element of document.getElementsByClassName("player-page")) {
            if (element.getAttribute("data-player-id") == playerID) {
                element.innerHTML = title;
                break;
            }
        }
    }
}

function receivedConfig(config) {
    if (!config.hasOwnProperty("endingPage")) {
        console.error("Invalid Config: " + config);
        return;
    }

    if (activeGameState == WKRGameState.race || activeGameState == WKRGameState.results) {
        updateStatusLabel((config["startingPage"]["title"] + " TO " + config["endingPage"]["title"]).toUpperCase());
    }
}

function receivedImageContainer(imageContainer) {
    if (!imageContainer.hasOwnProperty("items")) {
        console.error("Invalid Image Container: " + imageContainer);
        return;
    }
    activeImageContainerItems = imageContainer["items"];
    createInitalInterfaceIfNeeded();
}

function createInitalInterfaceIfNeeded() {
    if (initalInterfaceLoaded) {
        return;
    }

    initalInterfaceLoaded = true;

    let innerHTML = "";
    for (const playerID of Object.keys(activeImageContainerItems)) {
        innerHTML += playerContainerTemplateForPlayerID(playerID);
    }
    document.getElementById("players-container").innerHTML = innerHTML;
    document.getElementById("left-header-text").innerHTML = "PRIVATE RACE: " + activeRaceCode.toUpperCase();
}

function playerContainerTemplateForPlayerID(playerID) {
    return `
    <div class="player-container">
            <div class="player-inner-container">
            <img class="player-image" src="data:image/jpeg;base64,${activeImageContainerItems[playerID]}">
            <div class="player-name">${playerID}</div>
            <div class="player-page" data-player-id="${playerID}"></div>
        </div>
    </div>
    `;
}

function statusForGameState(state) {
    if (state == WKRGameState.preMatch) {
        return "PRERACE"
    } else if (state == WKRGameState.voting) {
        return "VOTING"
    } else if (state == WKRGameState.race) {
        return "RACE"
    } else if (state == WKRGameState.results) {
        return "END OF RACE"
    } else if (state == WKRGameState.hostResults) {
        return "END OF RACE"
    } else if (state == WKRGameState.points) {
        return "END OF RACE"
    } else {
        return "N/A"
    }
}

function updateStatusLabel(text) {
    document.getElementById("race-status").innerHTML = text;
}
