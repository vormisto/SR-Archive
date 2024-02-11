// Get user supplied info from form
const searchCity = document.getElementById("searchCity");
const fromDate = document.getElementById("fromDate");
const toDate = document.getElementById("toDate");

// This function is used to determine whether to search for rented or sold apartments
function getSelectedType() {
  var radios = document.getElementsByName('type');
  for (var i = 0; i < radios.length; i++) {
      if (radios[i].checked) {
          return radios[i].id;
      }
  }
  return null;
}

// Search if enter is pressed
const search = document.getElementById("search");
search.addEventListener("keypress", e => {
  if (e.keyCode === 13) {
    searchApartments();
  }
});

// Search if search button is clicked
const searchBtn = document.getElementById("searchBtn");
searchBtn.addEventListener("click", () => {
  searchApartments();
})

// Function to call the API to fetch listing data
function searchApartments() {
  fetch(`/search?city=${searchCity.value.trim()}&type=${getSelectedType()}&from=${fromDate.value}&to=${toDate.value}`)
  .then(data => data.json())
  .then(data => {
    if (Object.entries(data).length === 0) {
      showMsg("No results were found", "warning");
    } else if (data['message']) {
      showMsg(data['message'], "warning");
    } else if (data['error']) {
      showMsg(data['error'], "danger");
    }else {
      tableCreation(data);
    }
  });
}

// This function is used to show warning/error messages if fetching from API did not work
function showMsg(msg, type) {
  let output = `
  <div class="alert alert-${type}" role="alert">
    ${msg}
  </div>
  `
  document.getElementById("apartmentTable").innerHTML = output;
}

// Used to calculate how long listing was active
function dateDiff(start, end) {
  const startDate = new Date(start);
  const endDate = new Date(end);
  const secondsDiff = (endDate.getTime() - startDate.getTime()) / 1000;
  const daysDiff = Math.round(secondsDiff / (3600 * 24)) + 1;
  return daysDiff;
}

// This function is used to create the table to show listing data
function tableCreation(tabledata) {
  // Modify the results a bit
  let modifiedList = tabledata.map(item => {
    let dateObj = new Date(item.publishedDate);
    let formattedDate = dateObj.toISOString().split('T')[0];
    item.publishedDate = formattedDate;
    item.days = dateDiff(formattedDate, item.removedDate);
    item.size = parseFloat(item.size);
    return item;
  });

  // Custom max min header filter
  // Source: https://tabulator.info/examples/5.5#filter-header
  var minMaxFilterEditor = function(cell, onRendered, success, cancel, editorParams){
    var end;
    var container = document.createElement("div");
    var minContainer = document.createElement("div");
    var start = document.createElement("input");
    start.setAttribute("type", "number");
    start.setAttribute("placeholder", "Min");
    start.style.padding = "4px";
    start.style.width = "100%";
    start.style.boxSizing = "border-box";
    minContainer.appendChild(start);
    start.value = cell.getValue();
    function buildValues(){
        success({
            start:start.value,
            end:end.value,
        });
    }
    function keypress(e){
        if(e.keyCode == 13){
            buildValues();
        }
        if(e.keyCode == 27){
            cancel();
        }
    }
    end = start.cloneNode();
    end.setAttribute("placeholder", "Max");

    start.addEventListener("change", buildValues);
    start.addEventListener("blur", buildValues);
    start.addEventListener("keydown", keypress);

    end.addEventListener("change", buildValues);
    end.addEventListener("blur", buildValues);
    end.addEventListener("keydown", keypress);

    var maxContainer = document.createElement("div"); 
    maxContainer.appendChild(end); 

    container.appendChild(minContainer);
    container.appendChild(maxContainer);

    return container;
  }

  // Custom max min filter function
  // Source: https://tabulator.info/examples/5.5#filter-header
  function minMaxFilterFunction(headerValue, rowValue, rowData, filterParams){
    //headerValue - the value of the header filter element
    //rowValue - the value of the column in this row
    //rowData - the data for the row being filtered
    //filterParams - params object passed to the headerFilterFuncParams property
    if(rowValue){
        if(headerValue.start != ""){
            if(headerValue.end != ""){
                return rowValue >= headerValue.start && rowValue <= headerValue.end;
            }else{
                return rowValue >= headerValue.start;
            }
        }else{
            if(headerValue.end != ""){
                return rowValue <= headerValue.end;
            }
        }
    }
    return true; //must return a boolean, true if it passes the filter.
  }

  // Initialize the Tabulator table
  var table = new Tabulator("#apartmentTable", {
      data: modifiedList,
      columns: [
          {title:"District", field:"district", sorter:"string", minWidth:150, headerFilter:"input"},
          {title:"Address", field:"address", sorter:"string", minWidth:150, headerFilter:"input"},
          {title:"Room Configuration", field:"roomConfiguration", sorter:"string", minWidth:300, headerFilter:"input"},
          {title:"Floor", field:"floor", sorter:"string", width:95, headerFilter:"input"},
          {title:"Size", field:"size", sorter:"number", width: 120, bottomCalc:"avg", bottomCalcParams:{precision:0}, headerFilter:minMaxFilterEditor, headerFilterFunc:minMaxFilterFunction, headerFilterLiveFilter:false},
          {title:"Build Year", field:"buildYear", sorter:"number", width: 130, bottomCalc:"avg", bottomCalcParams:{precision:0}, headerFilter:minMaxFilterEditor, headerFilterFunc:minMaxFilterFunction, headerFilterLiveFilter:false},
          {title:"Price", field:"price", sorter:"number", width: 120, bottomCalc:"avg", bottomCalcParams:{precision:0}, headerFilter:minMaxFilterEditor, headerFilterFunc:minMaxFilterFunction, headerFilterLiveFilter:false},
          {title:"Published", field:"publishedDate", width: 130, sorter:"string"},
          {title:"Removed", field:"removedDate", width: 130, sorter:"string"},
          {title:"Days", field:"days", sorter:"number", width: 90, bottomCalc:"avg", bottomCalcParams:{precision:1}},
      ],
      layout:"fitColumns",
      renderHorizontal:"virtual",
      resizableColumnFit:true,
      pagination: "local", 
      paginationSize: 25, 
      columnHeaderSortMulti: true,
  });
};

// Set default date values for "to" and "from" fields
document.addEventListener("DOMContentLoaded", function() {
  var today = new Date();
  var sevenDaysAgo = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 7);

  function formatDate(date) {
    var d = new Date(date),
        month = '' + (d.getMonth() + 1),
        day = '' + d.getDate(),
        year = d.getFullYear();

    if (month.length < 2) 
        month = '0' + month;
    if (day.length < 2) 
        day = '0' + day;

    return [year, month, day].join('-');
  }

  document.getElementById('fromDate').value = formatDate(sevenDaysAgo);
  document.getElementById('toDate').value = formatDate(today);
});