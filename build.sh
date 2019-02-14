#!/bin/bash

# env
branch=${1:-master}
servicename=${2:-none}
registry="172.16.0.13:5000"
timestamp=`date +%Y%m%d%H%M%S`

if [ $servicename -eq "none" ] ; then
    echo 'servicename is none'
    exit 1
fi

# 检索出所有Dockerfile
Dockerfiles=`find -name Dockerfile`
echo "检索到Dockerfile：\n%s\n" "${Dockerfiles}"

j=0
for d in ${Dockerfiles} ; do
    ((j++))
done
echo "$j"
if [ "$j" -eq "0" ]; then
    echo '没有检索到Dokcerfile'
    exit 1
fi

# 单个module的项目
if [ "$j" -eq "1" ];
then
    echo "构建镜像：$registry/$servicename:$branch-$timestamp"
    docker build --build-arg ACTIVE=${branch} -t ${registry}/${servicename}:${branch}-${timestamp} .
    echo "上传镜像（tiemstamp）：$registry/$servicename:$branch-$timestamp"
    docker push ${registry}/${servicename}:${branch}-${timestamp}
    echo "上传镜像（latest）：$registry/$servicename:$branch-latest"
    docker tag ${registry}/${servicename}:${branch}-${timestamp} ${registry}/${servicename}:${branch}-latest
    docker push ${registry}/${servicename}:${branch}-latest
    echo "构建完成！"

# 多个module的项目
else
    # 检索到变更的module
    files=`git diff --name-only HEAD~ HEAD`
    echo "git提交的文件：\n%s\n" "${files[@]}"
    for module in ${Dockerfiles[@]}
    do
        module=`echo ${module%/*}`
        module=`echo ${module##*/}`
        if [[ $files =~ $module ]];then
            updatedModules[${#updatedModules[@]}]=`echo ${module}`
        fi
    done

    echo "准备操作的项目："
    echo "%s\n" "${updatedModules[@]}"
    if [ ${#updatedModules[@]} == 0 ]; then
        echo '不存在改动的项目'
        exit 1
    fi

    # build
    i=0
    for updatedModule in ${updatedModules[@]}
        do
            if [ "$i" -eq "0" ]; then
                cd ./$updatedModule
            else
                cd ../$updatedModule
            fi

            echo "构建镜像：$registry/$servicename:$branch-$timestamp"
            docker build --build-arg ACTIVE=${branch} -t ${registry}/${servicename}:${branch}-${timestamp} .
            echo "上传镜像（tiemstamp）：$registry/$servicename:$branch-$timestamp"
            docker push ${registry}/${servicename}:${branch}-${timestamp}
            echo "上传镜像（latest）：$registry/$servicename:$branch-latest"
            docker tag ${registry}/${servicename}:${branch}-${timestamp} ${registry}/${servicename}:${branch}-latest
            docker push ${registry}/${servicename}:${branch}-latest

            ((i++))
    done
    echo "构建完成！"
fi


