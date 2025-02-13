#Powershell Script
Function Get-GitlabFilesWithLastUpdate {
    param (
        [string]$project_id,
        [string]$token,
        [string]$branch = "main"
    )
    
    BEGIN {
        $repository_url = "https://YourGitAddress.com/api/v4/projects/$project_id/repository"
        $HEADERS = @{ "PRIVATE-TOKEN" = "$token" }
        
        # Get all files using pagination
        $page = 1
        $per_page = 100
        $files = @()

        do {
            $file_list_url = "$repository_url/tree?ref=$branch&per_page=$per_page&page=$page"
            try {
                $page_files = Invoke-RestMethod -Uri $file_list_url -Headers $HEADERS -Method Get
                $files += $page_files
                $page++
            } catch {
                Write-Error "Failed to fetch file list (Page $page): $_"
                break
            }
        } while ($page_files.Count -eq $per_page)  # Continue if the last page was full
    }
    
    PROCESS {
        if (-not $files) {
            Write-Error "No files found in the repository."
            return
        }

        $fileInfoList = @()
        foreach ($file in $files) {
            $file_path = $file.path
            $commit_url = "$repository_url/commits?path=$([uri]::EscapeDataString($file_path))&ref_name=$branch&per_page=1"
            
            try {
                $commit_data = Invoke-RestMethod -Uri $commit_url -Headers $HEADERS -Method Get
                
                if ($commit_data -and $commit_data.Count -gt 0) {
                    $last_commit = $commit_data[0]
                    
                    $fileInfoList += [PSCustomObject]@{
                        FileName      = $file.name
                        FilePath      = $file_path
                        LastUpdated   = $last_commit.created_at
                        LastCommitID  = $last_commit.id
                    }
                } else {
                    Write-Warning "No commit history found for $file_path"
                }
            } catch {
                Write-Warning "Failed to fetch last commit for $file_path : $_" 
            }
        }
        
        return $fileInfoList
    }
}

l
# Usage Example
$project_id = "123" #Your Git ID
$token = "GIT Token" #Your Git Access Token
$filesInfo = Get-GitlabFilesWithLastUpdate -project_id $project_id -token $token
$filesInfo | Format-Table -AutoSize
