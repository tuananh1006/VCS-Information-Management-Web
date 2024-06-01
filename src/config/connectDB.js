const config=require('./config.json')[start];
const sql = require('msnodesqlv8');

var server = config.server;
var database = config.database;
var driver=config.driver;
const connectionString = `server=${server};Database=${database};Trusted_Connection=Yes;Driver={${driver}}`;

const selectDatabase = (query) => {
    return new Promise((resolve, reject) => {
        sql.query(connectionString, query, (err, rows) => {
            if (err) {
                console.error('Lỗi khi thực hiện truy vấn bảng coach:', err);
                reject(err);
            } else {
                resolve(rows);
            }
        });
    });
};

const modifyDatabase = (query) => {
    return new Promise((resolve, reject) => {
        sql.query(connectionString, query, (err, result) => {
            if (err) {
                console.error('Lỗi khi thực hiện cập nhật:', err);
                reject(err);
            } else {
                console.log('Cập nhật thành công');
                resolve(result);
            }
        });
    });
};

const performModify = async (query) => {
    try {
        const result = await modifyDatabase(query);
        return result;
    } catch (err) {
        console.error('Lỗi khi cập nhật cơ sở dữ liệu:', err);
        throw err;
    }
};

performModify("insert into coach values('hoang',18)")



module.exports={
    selectDatabase,performModify
}




// const getFromselectDatabase = async (query)=>
//     {
//         result=await selectDatabase(query)
//         console.log(result)
//     }
    
//     getFromselectDatabase('select * from coach');