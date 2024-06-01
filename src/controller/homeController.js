import userService from '../service/userService'
import {selectDatabase,performModify} from '../config/connectDB'

const handleHomePage=(req,res)=>{
    return res.render('homepage.ejs')
}

const handleScheduler=async (req,res)=>{
        var query='select * from LICHTHIDAU'
        var result=await selectDatabase(query)
        console.log(result[0]['ĐỘI 1'])
        return res.render('scheduler.ejs',{result})
}

const handleRanking=(req,res)=>{
    return res.render('ranking.ejs')
}

const handleTeams=(req,res)=>{
    return res.render('teams.ejs')
}

const handlePlayers=(req,res)=>{
    return res.render('players.ejs')
}

const handleInformation=(req,res)=>{
    return res.render('information.ejs')
}


// 
module.exports={
    handleHomePage,handleScheduler,handleRanking,handleTeams,handlePlayers,handleInformation
}


// const handleTeam=(req,res)=>{
    //     var clubs=[{
    //         name:'Tun',
    //         wins:1,
    //         draws:1,
    //         losts:1,
    //         goalsFor:1,
    //         goalsAgainst:1,
    //         goalsDiff:1,
    //         point:1
    //     }]
    //     return res.render('team.ejs',{clubs})
    // }
    
    // const handleAddUser=(req,res)=>{
    //     let userList=userService.getUserList()
    //     return res.render('user-add.ejs',{userList})
    // }
    
    
    // const handleCreateUser=(req,res)=>{
    //     let email=req.body.email
    //     let password=req.body.password
    //     let username=req.body.username
    
    //     return res.redirect('/users/')
    // }