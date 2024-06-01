import bcrypt from 'bcryptjs';

const saltRounds = 10;
const salt = bcrypt.genSaltSync(saltRounds);

const hashUserPassword=(userPassword)=>{
    const hash = bcrypt.hashSync(userPassword, salt);
    return hash
}

const createNewUser=(email,password,username)=>{
    let hashPassword=hashUserPassword(password)


    //Connect DB


}

const getUserList=()=>{
    //connect.query
    return [{
        password:'123',
        email:'22520055@gm.uit.edu.vn',
        username:'tun'
    },{
        password:'123456',
        email:'22520044@gm.uit.edu.vn',
        username:'kim jong un'
    }]
}


module.exports={
    createNewUser,getUserList
}